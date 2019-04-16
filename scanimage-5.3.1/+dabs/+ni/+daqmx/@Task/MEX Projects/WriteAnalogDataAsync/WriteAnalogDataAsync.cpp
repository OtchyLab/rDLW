// WriteAnalogData.cpp : Defines the exported functions for the DLL application.
//
//% Method for asynchronously writing analog data to a Task containing one or more anlog output Channels
//%% function sampsPerChanWritten = writeAnalogDataAsync(task, writeData, timeout, autoStart, numSampsPerChan, callback)
//%   writeData: Data to write to the Channel(s) of this Task. Supplied as matrix, whose columns represent Channels.
//%              Data should be of numeric types double, uint16, or int16.
//%              Data of double type will be 'scaled' by DAQmx driver, which includes application of software calibration, for devices which support this.
//%              Data of uint16/int16 types will be 'unscaled' -- i.e. in the 'native' format of the device. Note such samples will not be calibrated in software.
//%
//%   timeout: <OPTIONAL - Default: inf) Time, in seconds, to wait for function to complete read. If 'inf' or < 0, then function will wait indefinitely. A value of 0 indicates to try once to write the submitted samples. If this function successfully writes all submitted samples, it does not return an error. Otherwise, the function returns a timeout error and returns the number of samples actually written.
//%   autoStart: <OPTIONAL - Logical - Default: false> Logical value specifies whether or not this function automatically starts the task if you do not start it. 
//%   numSampsPerChan: <OPTIONAL> Specifies number of samples per channel to write. If omitted/empty, the number of samples is inferred from number of rows in writeData array. 
//%   callback: <OPTIONAL> Specifies a matlab function handle that is called once the data is written
//%
//%
//%% NOTES
//%   If double data is supplied, the DAQmxWriteAnalogF64 function in DAQmx API is used. 
//%   If uint16/int16 data is supplied, the DAQmxWriteBinaryU16/I16 functions, respectively, in DAQmx API are used.
//%
//%   The 'dataLayout' parameter of DAQmx API functions is not supported -- data is always grouped by Channel (DAQmx_Val_GroupByChannel).
//%   This corresponds to Matlab matrix ordering where each Channel corresponds to one column. 
//%
//%   Some general rules:
//%       If you configured timing for your task (using a cfgXXXTiming() method), your write is considered a buffered write. The # of samples in the FIRST write call to Task configures the buffer size, unless cfgOutputBuffer() is called first.
//%       Note that a minimum buffer size of 2 samples is required, so a FIRST write operation of only 1 sample (without prior call to cfgOutputBuffer()) will generate an error.
//%


#include "stdafx.h"
#include "mex.h"
#include "NIDAQmx.h"
#include "AsyncMex.h"
#include <windows.h>
#include <stdio.h>
#include <process.h>
#include <string.h>
#include <iostream>
#include <time.h>

#define UTIL_NIDAQ_ERROR_BUFFER_SIZE (2048)

typedef struct {
   TaskHandle taskID;
   int numSampsPerChan;
   int8 autoStart;
   float64 timeout;
   void* aoData;
   mxClassID aoDataType;
   mxArray* cbFcnHdlMtlb;
   mxArray* hTaskMtlb;
   AsyncMex* asyncMex;
}threadData_t;

typedef struct {
   mxArray* cbFcnHdlMtlb;
   mxArray* hTaskMtlb;
   AsyncMex* asyncMex;
   int32 status;
   char* errBuff;
   char* errBuffEx;
   int32 sampsWritten;
}asyncMexCallbackData_t;

/*
Guarded_DAQmx
Example:
	Guarded_DAQmx(DAQmxWriteBinaryU16(...args...));

	If the DAQmxWriteBinary function fails with an error, a message will be printed
	in the matlab console and a matlab exception will be thrown ceasing further
	execution.

	If the call returns a non-critical error, a message will be printed and the error
	code will be returned.

	If the call is successfull, nothing is done, and DAQmxSuccess is returned.
*/
#define Guarded_DAQmx(expr) Guarded_DAQmx_(expr,#expr,__FILE__,__LINE__,__FUNCTION__)

static int32 Guarded_DAQmx_( int32 error, const char* expression, const char* file, const int line, const char* function )
{	
  char  errBuff[UTIL_NIDAQ_ERROR_BUFFER_SIZE]={'\0'},      
        errBuffEx[UTIL_NIDAQ_ERROR_BUFFER_SIZE]={'\0'};
  if( error == DAQmxSuccess)
	  return error;
  DAQmxGetErrorString(error, errBuff ,UTIL_NIDAQ_ERROR_BUFFER_SIZE);  // get error message
  DAQmxGetExtendedErrorInfo(errBuffEx,UTIL_NIDAQ_ERROR_BUFFER_SIZE);  // get error message
	
  if( DAQmxFailed(error) )
	mexPrintf( "(%s:%d) %s\n\t%s\n\t%s\n\t%s\n",file, line, function, (expression), errBuff, errBuffEx );// report
    mexErrMsgTxt("DAQmx call failed.");
  return error;
}

mxArray*
createMtlbStructEvtData(const asyncMexCallbackData_t* cbData)
{
	mwSize structDims[2] = {1,1};
	const char *field_names[] = {"sampsWritten","status","errorString","extendedErrorInfo"};
	int numFields = (int)(sizeof(field_names)/sizeof(*field_names));
	
	mxArray* mtlbEvtData =  mxCreateStructArray(2,structDims,numFields,field_names);
	mxSetField(mtlbEvtData,0,"sampsWritten",mxCreateDoubleScalar((double)cbData->sampsWritten));
	mxSetField(mtlbEvtData,0,"status",mxCreateDoubleScalar((double)cbData->status));
	mxSetField(mtlbEvtData,0,"errorString",mxCreateString(cbData->errBuff));
	mxSetField(mtlbEvtData,0,"extendedErrorInfo",mxCreateString(cbData->errBuffEx));
	
	return mtlbEvtData;
}

void
asyncMexMATLABCallback(LPARAM lParam, void* params)
{
	//lParam: Info supplied by postEventMessage
	//void *: Pointer to data/object specified at time of AsyncMex_create()
	asyncMexCallbackData_t* cbData = (asyncMexCallbackData_t*) lParam;

	
	mxArray* evtDataMtlb = createMtlbStructEvtData(cbData);
	mxArray* mException = NULL;

	if (cbData->cbFcnHdlMtlb==NULL || mxIsEmpty(cbData->cbFcnHdlMtlb)) {
		// no call back defined
	} else {
		if (mxIsClass( cbData->cbFcnHdlMtlb , "function_handle")) {
			mxArray* rhs[3];
			rhs[0] = cbData->cbFcnHdlMtlb;
			rhs[1] = cbData->hTaskMtlb;
			rhs[2] = evtDataMtlb;
			mException = mexCallMATLABWithTrap(0,(mxArray **)NULL,3,rhs,"feval");
		} else {
			mexPrintf("Not a Matlab Function handle");
		}		
	}
	
	//clean up persistent matlab arrays
	mxDestroyArray(cbData->cbFcnHdlMtlb);
	mxDestroyArray(cbData->hTaskMtlb);

	//clean up event data
	mxDestroyArray(evtDataMtlb);

	//clean up asyncmex object
	AsyncMex_destroy(&(cbData->asyncMex));

	//free heap
	if (cbData->errBuff != NULL) free(cbData->errBuff);
	if (cbData->errBuffEx != NULL) free(cbData->errBuffEx);
	free(cbData);

	//decrement lock counter
	mexUnlock();
	if(mException != NULL) mexPrintf("Error in callback for WriteAnalogDataAsync\n");
}

// thread function
void __cdecl writerThreadFunc( void* pArguments ) {
	threadData_t* threadData = (threadData_t*) pArguments;
	bool32 dataLayout = DAQmx_Val_GroupByChannel; //This forces DAQ toolbox like ordering, i.e. each Channel corresponds to a column
	 
	int32 sampsWritten = 0;
	int32 status = 0;
	
    int32 sampTimingType = 0;
    status = DAQmxGetSampTimingType(threadData->taskID, &sampTimingType);
    if (sampTimingType != DAQmx_Val_OnDemand) {
        status = DAQmxSetWriteWaitMode(threadData->taskID,DAQmx_Val_Yield);
    }
	
	if (threadData->autoStart < 0) {
		int32 sampTimingType = 0;
		status = (DAQmxGetSampTimingType(threadData->taskID,&sampTimingType));		
		threadData->autoStart = (sampTimingType==DAQmx_Val_OnDemand);
	}
	
	switch (threadData->aoDataType)
	{	
		case mxUINT16_CLASS:
			status = DAQmxWriteBinaryU16(threadData->taskID, threadData->numSampsPerChan, (bool32)threadData->autoStart, threadData->timeout, dataLayout, (uInt16*) threadData->aoData, &sampsWritten, NULL);
		break;

		case mxINT16_CLASS:
			status = DAQmxWriteBinaryI16(threadData->taskID, threadData->numSampsPerChan, (bool32)threadData->autoStart, threadData->timeout, dataLayout, (int16*) threadData->aoData, &sampsWritten, NULL);
		break;

		case mxDOUBLE_CLASS:
			status = DAQmxWriteAnalogF64(threadData->taskID, threadData->numSampsPerChan, (bool32)threadData->autoStart, threadData->timeout, dataLayout, (float64*) threadData->aoData, &sampsWritten, NULL);
		break;

		default: ; //this should never happen!
	}

	char* errBuff = NULL;
	char* errBuffEx = NULL; 
	
	if (status != DAQmxSuccess) {
		errBuff = (char*)malloc(UTIL_NIDAQ_ERROR_BUFFER_SIZE);
		errBuffEx = (char*)malloc(UTIL_NIDAQ_ERROR_BUFFER_SIZE);
		DAQmxGetErrorString(status, errBuff ,UTIL_NIDAQ_ERROR_BUFFER_SIZE); // get error message
		DAQmxGetExtendedErrorInfo(errBuffEx,UTIL_NIDAQ_ERROR_BUFFER_SIZE);  // get error message
	}
	
	asyncMexCallbackData_t* cbData = (asyncMexCallbackData_t*) malloc(sizeof(asyncMexCallbackData_t));
	cbData->status = status;
	cbData->errBuff = errBuff;
	cbData->errBuffEx = errBuffEx;
	cbData->sampsWritten = sampsWritten;
	cbData->cbFcnHdlMtlb = threadData->cbFcnHdlMtlb;
	cbData->hTaskMtlb = threadData ->hTaskMtlb;
	cbData->asyncMex = threadData->asyncMex;
	
    // clean up heap
	if(threadData->aoData != NULL) free(threadData->aoData);
	if(threadData != NULL) free(threadData);
	
	if(threadData->asyncMex != NULL)AsyncMex_postEventMessage(threadData->asyncMex,(LPARAM)cbData);
	 
	// end thread
	_endthread();
 }

//Gateway routine
//sampsPerChanWritten = writeAnalogData(task, writeData, timeout, autoStart, numSampsPerChan, callback)
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
	//no return value
	nlhs = 0;

	//General vars
	char errMsg[512];
	
	//Read input arguments
	float64 timeout;
	int numSampsPerChan;
	int8 autoStart;
	TaskHandle taskID, *taskIDPtr;
	mxArray* cbFcnHdlMtlb = NULL;
	mxArray* hTaskMtlb = NULL;
	
	// Argument Checking:

	//Get TaskHandle
	if  ((nrhs < 1) || mxIsEmpty(prhs[0])) {
		mexErrMsgTxt("First input argument is not a dabs.ni.daqmx.Task");
	} else {
		hTaskMtlb = mxDuplicateArray(prhs[0]);
		mexMakeArrayPersistent(hTaskMtlb);
		taskIDPtr = (TaskHandle*)mxGetData(mxGetProperty(prhs[0],0, "taskID"));
		taskID = *taskIDPtr;
	}
	
	//We will process the data later
	if ((nrhs < 2) || mxIsEmpty(prhs[1])) {
		return; // nothing to do
	}
	
	//Get Timeout
	if ((nrhs < 3) || mxIsEmpty(prhs[2])) {
		timeout = 10.0;
	} else {
		timeout = (float64) mxGetScalar(prhs[2]);
		if (mxIsInf(timeout))
			timeout = DAQmx_Val_WaitInfinitely;
	}

	//Get Autostart
	if ((nrhs < 4) || mxIsEmpty(prhs[3])) {
		autoStart = -1;
	} else {
		autoStart = (int8) mxGetScalar(prhs[3]);
	}

	//Get Number of Samples per Channel
	size_t numRows = mxGetM(prhs[1]);
	size_t numCols = mxGetN(prhs[1]);
	if ((nrhs < 5) || mxIsEmpty(prhs[4])) {
		numSampsPerChan = numRows;
	} else {
		numSampsPerChan = min((int) mxGetScalar(prhs[4]),numRows);
	}
	
	// Get callback function handle
	if (nrhs < 6 || mxIsEmpty(prhs[5])) {
		cbFcnHdlMtlb = NULL;
	} else {
		if(mxIsClass( prhs[5] , "function_handle")) {
			cbFcnHdlMtlb = mxDuplicateArray(prhs[5]);
			mexMakeArrayPersistent(cbFcnHdlMtlb);
		} else {
			mexErrMsgTxt("Sixth input argument is not a function handle.");
		}
	}

	if (numSampsPerChan <= 0) return; // nothing to do
	
	mxClassID aoDataType = mxGetClassID(prhs[1]);
	size_t bytesPerSample = 0;
	switch (aoDataType) {
		case mxUINT16_CLASS:
			bytesPerSample = sizeof(uInt16);
		break;

		case mxINT16_CLASS:
			bytesPerSample = sizeof(int16);
		break;

		case mxDOUBLE_CLASS:
			bytesPerSample = sizeof(float64);
		break;

		default:
			sprintf_s(errMsg,"Class of supplied writeData argument (%s) is not valid", mxGetClassName(prhs[1]));
			mexErrMsgTxt(errMsg);
	}
	
	// create a copy of the ao data on the heap so it can be accessed in the new thread
	size_t aoDataBytes = numSampsPerChan * numCols * bytesPerSample;
	void* aoData = malloc(aoDataBytes);
	if (aoData == NULL) mexErrMsgTxt("WriteAnalogDataAsync: Out of memory");
	memcpy (aoData, mxGetData(prhs[1]), aoDataBytes);
	
	// create threadData on hte heap so it can be accessed in the new thread
	threadData_t* threadData = (threadData_t*) malloc(sizeof(threadData_t));
	if (threadData == NULL) mexErrMsgTxt("WriteAnalogDataAsync: Out of memory");
	threadData->taskID = taskID;
	threadData->numSampsPerChan = numSampsPerChan;
	threadData->autoStart = autoStart;
	threadData->timeout = timeout;
	threadData->aoData = aoData;
	threadData->aoDataType = aoDataType;
	threadData->hTaskMtlb = hTaskMtlb;
	threadData->cbFcnHdlMtlb = cbFcnHdlMtlb;

	threadData->asyncMex = AsyncMex_create((AsyncMex_Callback *) asyncMexMATLABCallback , NULL);
	
	// start new thread, fire and forget; thread function should handle its own life time
	_beginthread(&writerThreadFunc, 0, (void*)threadData);

	mexLock(); // increment lock counter
	return;
}