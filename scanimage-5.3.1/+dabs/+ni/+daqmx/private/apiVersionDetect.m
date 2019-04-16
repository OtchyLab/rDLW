function [methodinfo,structs,enuminfo,ThunkLibName]=apiVersionDetect
%APIVERSIONDETECT Create structures to define interfaces found in 'NIDAQmx'.

%This function was generated by loadlibrary.m parser version 1.1.6.33 on Fri Sep 10 10:51:35 2010
%perl options:'NIDAQmx.i -outfile=apiVersionDetect.m'
ival={cell(1,0)}; % change 0 to the actual number of functions to preallocate the data.
structs=[];enuminfo=[];fcnNum=1;
fcns=struct('name',ival,'calltype',ival,'LHS',ival,'RHS',ival,'alias',ival);
ThunkLibName=[];
% int32 _stdcall DAQmxGetSysNIDAQMajorVersion ( uInt32 * data ); 
fcns.name{fcnNum}='DAQmxGetSysNIDAQMajorVersion'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}='long'; fcns.RHS{fcnNum}={'ulongPtr'};fcnNum=fcnNum+1;
% int32 _stdcall DAQmxGetSysNIDAQMinorVersion ( uInt32 * data ); 
fcns.name{fcnNum}='DAQmxGetSysNIDAQMinorVersion'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}='long'; fcns.RHS{fcnNum}={'ulongPtr'};fcnNum=fcnNum+1;
% int32 _stdcall DAQmxGetSysNIDAQUpdateVersion ( uInt32 * data ); 
fcns.name{fcnNum}='DAQmxGetSysNIDAQUpdateVersion'; fcns.calltype{fcnNum}='stdcall'; fcns.LHS{fcnNum}='long'; fcns.RHS{fcnNum}={'ulongPtr'};fcnNum=fcnNum+1;
methodinfo=fcns;
