classdef PDEPPropEventData < event.EventData
    %
    % event.EventData subclass for PDEP 'setSuccess' event
    %
    
    properties
        pdepPropName = '';
    end
    
    methods        
        function obj = PDEPPropEventData(name)
            obj.pdepPropName = name;
        end
    end
    
end


%--------------------------------------------------------------------------%
% PDEPPropEventData.m                                                      %
% Copyright � 2016 Vidrio Technologies, LLC                                %
%                                                                          %
% ScanImage 2016 is premium software to be used under the purchased terms  %
% Code may be modified, but not redistributed without the permission       %
% of Vidrio Technologies, LLC                                              %
%--------------------------------------------------------------------------%
