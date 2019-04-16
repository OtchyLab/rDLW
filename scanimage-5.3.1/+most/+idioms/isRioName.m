function tf = isRioName(nm)
    tf = strncmp(nm,'RIO',3) && all(isstrprop(nm(4:end),'digit'));
end

%--------------------------------------------------------------------------%
% isRioName.m                                                              %
% Copyright © 2016 Vidrio Technologies, LLC                                %
%                                                                          %
% ScanImage 2016 is premium software to be used under the purchased terms  %
% Code may be modified, but not redistributed without the permission       %
% of Vidrio Technologies, LLC                                              %
%--------------------------------------------------------------------------%
