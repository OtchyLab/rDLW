function tf = inRange(val, set)
    if length(set) == 1
        tf = (val == set);
    else
        tf = ((val>=set(1)) && (val<=set(end))) || ((val<=set(1)) && (val>=set(end)));
    end
end

%--------------------------------------------------------------------------%
% inRange.m                                                                %
% Copyright © 2016 Vidrio Technologies, LLC                                %
%                                                                          %
% ScanImage 2016 is premium software to be used under the purchased terms  %
% Code may be modified, but not redistributed without the permission       %
% of Vidrio Technologies, LLC                                              %
%--------------------------------------------------------------------------%
