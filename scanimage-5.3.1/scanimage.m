function scanimage(varargin)
% SCANIMAGE     starts ScanImage application and its GUI(s)
%
%   It places two variables in the base workspace.
%   hSI is a scanimage.SI object that gives access to the operation and
%   configuration of the microscope.  hSICtl gives access to the user
%   interface elements.  There is implicit synchronization between the
%   microscope configuration and the user interface, so most of the time,
%   hSICtl can be safely ignored.
%
%   See also scanimage.SI and scanimage.SIController

mdf = '';
usr = [];
hidegui = false;

list = what('scanimage');
mask = cellfun(@(m)any(strcmpi(m,'SI.m')),{list.m});
numSI = sum(mask);

if numSI > 1
    msgbox('Multiple ScanImage installations were found on the path.','Error','error');
    folders = strjoin({list(mask).path},'\n\t');
    error('Multiple ScanImage installations were found on the path:\n\t%s\nRemove the redundant instances from the path and restart Matlab.',folders);
end

if nargin > 0 && ischar(varargin{1})
    mdf = varargin{1};
    assert(logical(exist(mdf,'file')), 'Specified machine data file not found.');
end

if nargin > 1 && ischar(varargin{2})
    usr = varargin{2};
    if ~isempty(usr)
        assert(logical(exist(usr,'file')), 'Specified usr file not found.');
    end
end

if nargin > 2
    for i = 3:nargin
        if ischar(varargin{i}) && strcmp(varargin{i}, '-hidegui')
            hidegui = true;
        end
    end
end

if evalin('base','~exist(''hSI'')')
    
    hCE = scanimage.guis.ConfigurationEditor([],false,true); %ConfigurationEditor(mdfPath,initNow,persist)
    
    if isempty(mdf) || isnumeric(usr) || ~hidegui
        [mdf,usr,runSI] = scanimage.guis.StartupConfig.doModalConfigPrompt(mdf,usr,hCE);
        if ~runSI
            most.idioms.safeDeleteObj(hCE);
            return;
        end
    end
    
    try
        hSI = scanimage.SI(mdf,hCE);
        hSIBasename = 'hSI';
        assignin('base',hSIBasename,hSI); % assign object in base as soon as it is constructed
        hSI.initialize();
        
        hSICtl = scanimage.SIController(hSI);
        hSICtl.hConfigEditor = hCE;
        assignin('base','hSICtl',hSI.hController{1}); % assign object in base as soon as it is constructed
        hSICtl.initialize(usr,hidegui);
        hSICtl.attachPropBindingsToToolTipStrings(['Command line: ' hSIBasename '.']);
        
    catch ME
        if exist('hSI', 'var')
            most.idioms.safeDeleteObj(hSI);
        end
        
        most.idioms.safeDeleteObj(hCE);
        evalin('base','clear hSI hSICtl MachineDataFile');
        
        if strcmp(ME.message, 'MachineDateFile: Operation canceled.')
            most.idioms.warn(ME.message);
        else
            ME.rethrow;
        end
    end
elseif evalin('base','~exist(''hSICtl'')')
    try
        hSICtl = scanimage.SIController(evalin('base','hSI'));
        assignin('base','hSICtl',hSICtl);
        hSICtl.initialize(usr,hidegui);
        hSICtl.attachPropBindingsToToolTipStrings(['Command line: hSI.']);
        
    catch ME
        evalin('base','clear hSICtl');
        ME.rethrow;
    end
else
    most.idioms.warn('ScanImage is already running.');
    evalin('base','hSICtl.raiseAllGUIs')
end
end


%--------------------------------------------------------------------------%
% scanimage.m                                                              %
% Copyright © 2016 Vidrio Technologies, LLC                                %
%                                                                          %
% ScanImage 2016 is premium software to be used under the purchased terms  %
% Code may be modified, but not redistributed without the permission       %
% of Vidrio Technologies, LLC                                              %
%--------------------------------------------------------------------------%
