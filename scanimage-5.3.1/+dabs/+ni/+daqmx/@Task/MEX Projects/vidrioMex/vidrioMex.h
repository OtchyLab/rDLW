#pragma once
#include "stdafx.h"
#include "mex.h"
#include <stdint.h>
#include <string.h>

mxArray *createInt32Scalar(int32_t v);

mxArray *createStringN(char *str, int N);

void returnInt32Val(int32_t r, int nlhs, mxArray *plhs[]);

void returnUInt32Val(uint32_t r, int nlhs, mxArray *plhs[]);

void returnUInt32ValArgN(uint32_t r, int N, int nlhs, mxArray *plhs[]);

void returnUInt64Val(uint64_t r, int nlhs, mxArray *plhs[]);

void returnUInt64ValArgN(uint64_t r, int N, int nlhs, mxArray *plhs[]);

void returnString(char *str, int nlhs, mxArray *plhs[]);

void returnStringN(char *str, int N, int nlhs, mxArray *plhs[]);

void returnLogicalVal(bool r, int nlhs, mxArray *plhs[]);

bool getLogical(const mxArray *arr, bool defaultVal);

double getDouble(const mxArray *arr, double defaultVal);

int getInteger(const mxArray *arr, int defaultVal);

uint64_t getUInt64(const mxArray *arr, uint64_t defaultVal);

size_t getStr(const mxArray *arr, char **val);

bool getStr(const mxArray *arr, char *val, size_t len);

bool getMtlbObjPropertyDbl(const mxArray *mtlbObj, const char *propname, double * const val, double defaultVal);

bool getMtlbObjPropertyUInt32(const mxArray *mtlbObj, const char *propname, uint32_t * const val, uint32_t defaultVal);

bool getMtlbObjPropertyStr(const mxArray *mtlbObj, const char *propname, char **val);



mxArray *createInt32Scalar(int32_t v)
{
	mxArray *arr;
	int32_t *datPtr;
	mwSize sz = 1;

	arr = mxCreateNumericArray(1, &sz, mxINT32_CLASS, mxREAL);
	datPtr = (int32_t*)mxGetData(arr);
	*datPtr = v;

	return arr;
}

mxArray *createStringN(char *str, int N)
{
	mxArray *arr;
	wchar_t *datPtr;
	mwSize sz[2];
		
	sz[0] = 1;
	sz[1] = N;

	arr = mxCreateCharArray(2, sz);
	datPtr = (wchar_t*)mxGetData(arr);
	if(datPtr)
	{
		// convert character encoding
		for(int i = 0; i < N; i++)
			datPtr[i] = str[i];
	}

	return arr;
}

void returnInt32Val(int32_t r, int nlhs, mxArray *plhs[])
{
	if(nlhs)
	{
		int32_t *datPtr;
		mwSize sz = 1;

		plhs[0] = mxCreateNumericArray(1, &sz, mxINT32_CLASS, mxREAL);
		datPtr = (int32_t*)mxGetData(plhs[0]);

		if(datPtr)
			*datPtr = (int32_t)r;
	}
}

void returnUInt32Val(uint32_t r, int nlhs, mxArray *plhs[])
{
	if(nlhs)
	{
		uint32_t *datPtr;
		mwSize sz = 1;

		plhs[0] = mxCreateNumericArray(1, &sz, mxUINT32_CLASS, mxREAL);
		datPtr = (uint32_t*)mxGetData(plhs[0]);

		if(datPtr)
			*datPtr = (uint32_t)r;
	}
}

void returnUInt32ValArgN(uint32_t r, int N, int nlhs, mxArray *plhs[])
{
	if(nlhs > N)
	{
		uint32_t *datPtr;
		mwSize sz = 1;

		plhs[N] = mxCreateNumericArray(1, &sz, mxUINT32_CLASS, mxREAL);
		datPtr = (uint32_t*)mxGetData(plhs[N]);

		if(datPtr)
			*datPtr = (uint32_t)r;
	}
}

void returnUInt64Val(uint64_t r, int nlhs, mxArray *plhs[])
{
	if (nlhs)
	{
		uint64_t *datPtr;
		mwSize sz = 1;

		plhs[0] = mxCreateNumericArray(1, &sz, mxUINT64_CLASS, mxREAL);
		datPtr = (uint64_t*)mxGetData(plhs[0]);

		if (datPtr)
			*datPtr = (uint64_t)r;
	}
}

void returnUInt64ValArgN(uint64_t r, int N, int nlhs, mxArray *plhs[])
{
	if (nlhs > N)
	{
		uint64_t *datPtr;
		mwSize sz = 1;

		plhs[N] = mxCreateNumericArray(1, &sz, mxUINT64_CLASS, mxREAL);
		datPtr = (uint64_t*)mxGetData(plhs[N]);

		if (datPtr)
			*datPtr = (uint64_t)r;
	}
}

void returnString(char *str, int nlhs, mxArray *plhs[])
{
	if(nlhs)
	{
		plhs[0] = mxCreateString(str);
	}
}

void returnStringN(char *str, int N, int nlhs, mxArray *plhs[])
{
	if(nlhs)
	{
		
		wchar_t *datPtr;
		mwSize sz[2];
		
		sz[0] = 1;
		sz[1] = N;

		plhs[0] = mxCreateCharArray(2, sz);
		datPtr = (wchar_t*)mxGetData(plhs[0]);
		if(datPtr)
		{
			// convert character encoding
			for(int i = 0; i < N; i++)
				datPtr[i] = str[i];
		}
	}
}

void returnLogicalVal(bool r, int nlhs, mxArray *plhs[])
{
	if(nlhs)
	{
		uint8_t *datPtr;
		mwSize sz = 1;

		plhs[0] = mxCreateNumericArray(1, &sz, mxLOGICAL_CLASS, mxREAL);
		datPtr = (uint8_t*)mxGetData(plhs[0]);

		if(datPtr)
			*datPtr = (int)r;
	}
}

bool getLogical(const mxArray *arr, bool defaultVal)
{
	void *dat = mxGetData(arr);

	if(!dat)
		return defaultVal;

	switch(mxGetClassID(arr))
	{
	case mxLOGICAL_CLASS :
	case mxINT8_CLASS :
	case mxUINT8_CLASS :
		return (*((uint8_t*)dat)) != 0;

	case mxINT16_CLASS :
	case mxUINT16_CLASS :
		return (*((uint16_t*)dat)) != 0;

	case mxINT32_CLASS :
	case mxUINT32_CLASS :
		return (*((uint32_t*)dat)) != 0;

	case mxINT64_CLASS :
	case mxUINT64_CLASS :
		return (*((uint64_t*)dat)) != 0;

	case mxSINGLE_CLASS :
		return (*((float*)dat)) != 0;

	case mxDOUBLE_CLASS :
		return (*((double*)dat)) != 0;

	default :
		return defaultVal;
	}
}


double getDouble(const mxArray *arr, double defaultVal)
{
	void *dat = mxGetData(arr);

	if(!dat)
		return defaultVal;

	switch(mxGetClassID(arr))
	{
	case mxLOGICAL_CLASS :
	case mxUINT8_CLASS :
		return (*((uint8_t*)dat));

	case mxINT8_CLASS :
		return (*((int8_t*)dat));

	case mxUINT16_CLASS :
		return (*((uint16_t*)dat));

	case mxINT16_CLASS :
		return (*((int16_t*)dat));

	case mxUINT32_CLASS :
		return (*((uint32_t*)dat));

	case mxINT32_CLASS :
		return (*((int32_t*)dat));

	case mxUINT64_CLASS :
		return (*((uint64_t*)dat));

	case mxINT64_CLASS :
		return (*((int64_t*)dat));

	case mxSINGLE_CLASS :
		return (*((float*)dat));

	case mxDOUBLE_CLASS :
		return (*((double*)dat));

	default :
		return defaultVal;
	}
}


int getInteger(const mxArray *arr, int defaultVal)
{
	void *dat = mxGetData(arr);

	if(!dat)
		return defaultVal;

	switch(mxGetClassID(arr))
	{
	case mxLOGICAL_CLASS :
	case mxUINT8_CLASS :
		return (*((uint8_t*)dat));

	case mxINT8_CLASS :
		return (*((int8_t*)dat));

	case mxUINT16_CLASS :
		return (*((uint16_t*)dat));

	case mxINT16_CLASS :
		return (*((int16_t*)dat));

	case mxUINT32_CLASS :
		return (*((uint32_t*)dat));

	case mxINT32_CLASS :
		return (*((int32_t*)dat));

	case mxUINT64_CLASS :
		return (*((uint64_t*)dat));

	case mxINT64_CLASS :
		return (*((int64_t*)dat));

	case mxSINGLE_CLASS :
		return (*((float*)dat));

	case mxDOUBLE_CLASS :
		return (*((double*)dat));

	default :
		return defaultVal;
	}
}

uint64_t getUInt64(const mxArray *arr, uint64_t defaultVal)
{
	void *dat = mxGetData(arr);

	if (!dat)
		return defaultVal;

	switch (mxGetClassID(arr))
	{
	case mxUINT64_CLASS:
		return (*((uint64_t*)dat));
	default:
		return defaultVal;
	}
}

size_t getStr(const mxArray *arr, char **val) //document that this allocates
{
	bool success = false;
	size_t buflen = mxGetNumberOfElements(arr) + 1;

	if(buflen > 1)
	{
		char *buf = new char[buflen];
		if(buf)
		{
			success = (mxGetString(arr,buf,(mwSize)buflen) == 0);
			if(success)
			{
				*val = buf;
				return buflen-1;
			}
			else
				delete[] buf;
		}
	}

	*val = NULL;
	return 0;
}

bool getStr(const mxArray *arr, char *val, size_t len)
{
	return mxGetString(arr, val, (mwSize)len) == 0;
}

bool getMtlbObjPropertyDbl(const mxArray *mtlbObj, const char *propname, double * const val, double defaultVal)
{
	mxArray* propVal = mxGetProperty(mtlbObj,0,propname);
	if(propVal)
	{
		*val = (double)mxGetScalar(propVal);
		mxDestroyArray(propVal);
		return true;
	}
	else
	{
		*val = defaultVal;
		return false;
	}
}

bool getMtlbObjPropertyStr(const mxArray *mtlbObj, const char *propname, char **val)
{
	bool success = false;
	mxArray* propVal = mxGetProperty(mtlbObj,0,propname);
	*val = NULL;

	if(propVal)
	{
		size_t buflen = mxGetNumberOfElements(propVal) + 1;
		if(buflen > 1)
		{
			char *buf = new char[buflen];
			if(buf)
			{
				*val = buf;
				success = (mxGetString(propVal,buf,(mwSize)buflen) == 0);
			}
		}
		mxDestroyArray(propVal);
	}

	return success;
}

bool getMtlbObjPropertyUInt32(const mxArray *mtlbObj, const char *propname, uint32_t * const val, uint32_t defaultVal)
{
	mxArray* propVal = mxGetProperty(mtlbObj,0,propname);
	if(propVal)
	{
		*val = (uint32_t)mxGetScalar(propVal);
		mxDestroyArray(propVal);
		return true;
	}
	else
	{
		*val = defaultVal;
		return false;
	}
}