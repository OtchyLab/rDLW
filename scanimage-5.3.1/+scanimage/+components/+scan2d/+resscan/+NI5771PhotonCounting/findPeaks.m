function threshIdxs = findPeaks(data,threshold,maskBefore,maskAfter,debounceSamples)
if nargin<3 || isempty(maskBefore)
    maskBefore = true(1,8);
end

if nargin<4 || isempty(maskAfter)
    maskAfter = true(1,8);
end

if nargin<5 || isempty(debounceSamples)
    debounceSamples = 8;    
end

mask = data >= threshold;
threshIdxs = find(mask);

maskBefore = find(maskBefore);
maskAfter = find(maskAfter);

mask = [fliplr(-maskBefore(:)') maskAfter(:)'];

%fprintf('Threshold detection completed, %d samples remaining',length(threshIdxs));

for idx = 1:length(threshIdxs)
    sampleIdx = threshIdxs(idx);
    
    if sampleIdx > length(data)-length(maskAfter) || sampleIdx <= length(maskBefore)
        continue
    end
    
    if ~all(data(sampleIdx) >= data(sampleIdx+mask))
        threshIdxs(idx) = NaN;
    end
end

nanMask = isnan(threshIdxs);
threshIdxs(nanMask) = [];

% find risingEdges

d = diff(threshIdxs);
dMask = find(d<=debounceSamples) + 1;
threshIdxs(dMask) = [];

end

%--------------------------------------------------------------------------%
% findPeaks.m                                                              %
% Copyright © 2016 Vidrio Technologies, LLC                                %
%                                                                          %
% ScanImage 2016 is premium software to be used under the purchased terms  %
% Code may be modified, but not redistributed without the permission       %
% of Vidrio Technologies, LLC                                              %
%--------------------------------------------------------------------------%
