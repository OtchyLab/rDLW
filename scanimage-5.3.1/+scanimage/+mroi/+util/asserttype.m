function asserttype(val,typestr)
assert(isa(val,typestr),'MROI:TypeError','Got type %s.  Expected type %s.',class(val),typestr);
end


%--------------------------------------------------------------------------%
% asserttype.m                                                             %
% Copyright � 2016 Vidrio Technologies, LLC                                %
%                                                                          %
% ScanImage 2016 is premium software to be used under the purchased terms  %
% Code may be modified, but not redistributed without the permission       %
% of Vidrio Technologies, LLC                                              %
%--------------------------------------------------------------------------%
