classdef PhotonDiscriminator < handle   
    properties (SetObservable)
        autoApplyChanges = false;
        
        rawDataScaleByPowerOf2Channel0 = 0;
        rawDataScaleByPowerOf2Channel1 = 0;
        staticNoiseChannel0 = 0;
        staticNoiseChannel1 = 0;
        differentiateChannel0 = false;
        differentiateChannel1 = false;
        filterCoefficientsChannel0;
        filterCoefficientsChannel1;
        peakThresholdChannel0 = 0;
        peakThresholdChannel1 = 0;
        peakDetectionWindowSizeChannel0 = 17;
        peakDetectionWindowSizeChannel1 = 17;
        peakDebounceSamplesChannel0 = 8;
        peakDebounceSamplesChannel1 = 8;
        phaseChannel0 = 0;
        phaseChannel1 = 0;
    end
    
    properties (SetAccess = private, Hidden)
        hSampler;
        hFpga;
        hDelayedEventListener;
        needsUpdate = true;
        simulated = false;
    end
    
    properties (Dependent, SetObservable)
        filterChannel0Delay; 
        filterChannel1Delay;
    end
    
    events (NotifyAccess = private)
        configurationChanged;
    end
    
    methods
        function obj = PhotonDiscriminator(hSampler)
            if nargin < 1 || isempty(hSampler)
                obj.simulated = true;
            else
                obj.hSampler = hSampler;
                obj.hFpga = obj.hSampler.hFpga;
            end
            
            obj.filterCoefficientsChannel0 = []; % initialize filterCoefficients to sensible value
            obj.filterCoefficientsChannel1 = []; % initialize filterCoefficients to sensible value

            obj.hDelayedEventListener = most.util.DelayedEventListener(0.5,obj,'configurationChanged',@obj.autoUpdateConfigurationCallback);
            obj.autoApplyChanges = true;
        end
        
        function delete(obj)
            most.idioms.safeDeleteObj(obj.hDelayedEventListener);
            %No-op
        end
        
        function s = saveStruct(obj)
            s = struct();
            s.autoApplyChanges = obj.autoApplyChanges;
            s.rawDataScaleByPowerOf2Channel0 = obj.rawDataScaleByPowerOf2Channel0;
            s.rawDataScaleByPowerOf2Channel1 = obj.rawDataScaleByPowerOf2Channel1;
            s.staticNoiseChannel0 = obj.staticNoiseChannel0;
            s.staticNoiseChannel1 = obj.staticNoiseChannel1;
            s.differentiateChannel0 = obj.differentiateChannel0;
            s.differentiateChannel1 = obj.differentiateChannel1;
            s.filterCoefficientsChannel0 = obj.filterCoefficientsChannel0;
            s.filterCoefficientsChannel1 = obj.filterCoefficientsChannel1;
            s.peakThresholdChannel0 = obj.peakThresholdChannel0;
            s.peakThresholdChannel1 = obj.peakThresholdChannel1;
            s.peakDetectionWindowSizeChannel0 = obj.peakDetectionWindowSizeChannel0;
            s.peakDetectionWindowSizeChannel1 = obj.peakDetectionWindowSizeChannel1;
            s.peakDebounceSamplesChannel0 = obj.peakDebounceSamplesChannel0;
            s.peakDebounceSamplesChannel1 = obj.peakDebounceSamplesChannel1;
            s.phaseChannel0 = obj.phaseChannel0;
            s.phaseChannel1= obj.phaseChannel1;
        end
        
        function loadStruct(obj,s)
            assert(isa(s,'struct'));
            
            props = fieldnames(s);
            for idx = 1:length(props)
                prop = props{idx};
                try
                    obj.(prop) = s.(prop);
                catch ME
                    most.idioms.reportError(ME);
                end
            end
        end
    end
    
    methods (Hidden)
        function propertyChanged(obj)
            obj.needsUpdate = true;
            notify(obj,'configurationChanged');
        end
        
        function autoUpdateConfigurationCallback(obj,src,evt)
            if obj.needsUpdate
                obj.configure();
            end
        end
    end
    
    methods        
        function configure(obj)
            obj.needsUpdate = false;
            
            if obj.simulated
                return
            end
            
            obj.hFpga.NI5771PhotonCountingRawDataScaleByPowerOf2Channel0 = obj.rawDataScaleByPowerOf2Channel0;
            obj.hFpga.NI5771PhotonCountingRawDataScaleByPowerOf2Channel1 = obj.rawDataScaleByPowerOf2Channel1;
            
            obj.hFpga.NI5771PhotonCountingStaticNoiseChannel0 = expandStaticNoise(obj.staticNoiseChannel0);
            obj.hFpga.NI5771PhotonCountingStaticNoiseChannel1 = expandStaticNoise(obj.staticNoiseChannel1);
            
            obj.hFpga.NI5771PhotonCountingDifferentiateChannel0 = obj.differentiateChannel0;
            obj.hFpga.NI5771PhotonCountingDifferentiateChannel1 = obj.differentiateChannel1;
            
            obj.hFpga.NI5771PhotonCountingFilterCoefficientsChannel0 = obj.filterCoefficientsChannel0;
            obj.hFpga.NI5771PhotonCountingRawDataDelayChannel0 = obj.filterChannel0Delay; % keep photon counting in sync with integration
            obj.hFpga.NI5771PhotonCountingFilterCoefficientsChannel1 = obj.filterCoefficientsChannel1;
            obj.hFpga.NI5771PhotonCountingRawDataDelayChannel0 = obj.filterChannel1Delay; % keep photon counting in sync with integration
            
            obj.hFpga.NI5771PhotonCountingPeakMaskChannel0 = makePeakWindowMask(obj.peakDetectionWindowSizeChannel0);
            obj.hFpga.NI5771PhotonCountingPeakMaskChannel1 = makePeakWindowMask(obj.peakDetectionWindowSizeChannel1);
            
            obj.hFpga.NI5771PhotonCountingPeakDebounceMaskChannel0 = makeDebounceMask(obj.peakDebounceSamplesChannel0);
            obj.hFpga.NI5771PhotonCountingPeakDebounceMaskChannel1 = makeDebounceMask(obj.peakDebounceSamplesChannel1);
            
            obj.hFpga.NI5771PhotonCountingPeakThresholdChannel0 = obj.peakThresholdChannel0;
            obj.hFpga.NI5771PhotonCountingPeakThresholdChannel1 = obj.peakThresholdChannel1;
            
            obj.hFpga.NI5771PhotonCountingPhaseChannel0 = obj.phaseChannel0;
            obj.hFpga.NI5771PhotonCountingPhaseChannel1 = obj.phaseChannel1;
            
            function peakMask_uint16 = makePeakWindowMask(windowSize)
                validateattributes(windowSize,{'numeric'},{'scalar','integer','positive','>=',3,'<=',17});
                assert(mod(windowSize,2)==1);
                
                peakMask_uint16 = uint16(0);
                
                for idx = 1:((windowSize-1)/2)
                    peakMask_uint16 = bitset(peakMask_uint16,idx,1);    % peak mask before
                    peakMask_uint16 = bitset(peakMask_uint16,idx+8,1);  % peak mask after
                end
            end
            
            function debounceMask_uint16 = makeDebounceMask(debounceSamples)
                debounceMask_uint16 = zeros(1,1,'uint16');
                for bitidx = 1:debounceSamples
                    debounceMask_uint16 = bitset(debounceMask_uint16,bitidx,true);
                end
            end
            
            function noise = expandStaticNoise(noise)                
                validateattributes(noise,{'numeric'},{'vector','integer','>=',-2^15,'<',2^15});
                assert(length(noise)<=128);
                assert(mod(128,length(noise))==0);
                noise = repmat(noise(:),128/length(noise),1);
            end
        end
        
        function [denoised,filtered,photonIdxs,photonHistogram] = processData(obj,data,channel,plotTF)
            if nargin<3 || isempty(plotTF)
                plotTF = false;
            end
            
            if obj.simulated || obj.hSampler.twoGroups
                numBinsHistogram = 16;
            else
                numBinsHistogram = 8;
            end
                        
            if size(data,2) == 2
                [denoisedCh0,filteredCh0,photonIdxsCh0,photonHistogramCh0] = processChannel0(data(:,1),plotTF);
                [denoisedCh1,filteredCh1,photonIdxsCh1,photonHistogramCh1] = processChannel1(data(:,2),plotTF);
                denoised = horzcat(denoisedCh0,denoisedCh1);
                filtered = horzcat(filteredCh0,filteredCh1);
                photonIdxs = {photonIdxsCh0,photonIdxsCh1};
                photonHistogram = horzcat(photonHistogramCh0,photonHistogramCh1);
            elseif channel == 0
                [denoised,filtered,photonIdxs,photonHistogram] = processChannel0(data,plotTF);
                photonIdxs = {photonIdxs};
            elseif channel == 1
                [denoised,filtered,photonIdxs,photonHistogram] = processChannel1(data,plotTF);
                photonIdxs = {photonIdxs};
            else
                error();
            end
            
            function [denoised,filtered,photonIdxs,histogram_] = processChannel0(data,plotTf)
                [denoised,filtered,photonIdxs,histogram_] = processPipeline(...
                    data,obj.rawDataScaleByPowerOf2Channel0,obj.staticNoiseChannel0,...
                    obj.differentiateChannel0,obj.filterCoefficientsChannel0,obj.peakThresholdChannel0,...
                    obj.peakDetectionWindowSizeChannel0,obj.peakDebounceSamplesChannel0,...
                    obj.phaseChannel0,numBinsHistogram);
                if plotTf
                    plotData([],'Channel 0',obj.peakThresholdChannel0,data,denoised,filtered,photonIdxs,histogram_);
                end
            end
            
            function [denoised,filtered,photonIdxs,histogram_] = processChannel1(data,plotTf)
                [denoised,filtered,photonIdxs,histogram_] = processPipeline(...
                    data,obj.rawDataScaleByPowerOf2Channel1,obj.staticNoiseChannel1,...
                    obj.differentiateChannel1,obj.filterCoefficientsChannel1,obj.peakThresholdChannel1,...
                    obj.peakDetectionWindowSizeChannel1,obj.peakDebounceSamplesChannel1,...
                    obj.phaseChannel1,numBinsHistogram);
                if plotTf
                    plotData([],'Channel 1',obj.peakThresholdChannel1,data,denoised,filtered,photonIdxs,histogram_);
                end
            end
            
            function [denoised,filtered,photonIdxs,histogram_] = processPipeline(...
                data,rawDataScaleByPowerOf2,staticNoise,differentiate,filterCoefficients,...
                peakThreshold,peakWindowSize,peakDebounceSamples,phase,...
                numBinsHistogram)
            
                data = double(data);
                
                %%% pre-scaling
                validateattributes(rawDataScaleByPowerOf2,{'numeric'},{'integer','nonnegative','<=',8});
                data = bitshift(data,rawDataScaleByPowerOf2,'int16');
                % output of bitshift on FPGA is int16
                
                %%% noise subtraction
                if any(staticNoise~=0)
                    validateattributes(staticNoise,{'numeric'},{'vector','integer','>=',-2^15,'<',2^15});
                    data = reshape(data,numel(staticNoise),[]);
                    data = bsxfun(@minus,data,staticNoise(:));
                    denoised = data(:);
                    % output of subtraction on FPGA is <+-17,17> -> should not be
                else
                    denoised = data;
                end
                
                if differentiate
                    denoised = denoised(3:end)-denoised(1:end-2); % centered differentiation
                    denoised = [0; denoised; 0];
                end
                
                %%% filter
                if filterCoefficients(1)~=1 || any(filterCoefficients(2:end)~=0)
                    validateattributes(filterCoefficients,{'numeric'},{'vector','numel',32,'integer','>=',-2^29,'<',2^29});
                    filtered = filter(double(filterCoefficients),1,denoised);
                    % output on FPGA is <+-,48,48>; we cannot easily bound-check
                    % each individual filter stage here
                    assert(all((filtered >=-2^47) & (filtered<2^47)),'Overflow in filter stage');
                else
                    filtered = denoised;
                end
                
                %%% peakDetection
                validateattributes(peakThreshold,{'numeric'},{'scalar','integer','>=',-2^47,'<',2^47});
                validateattributes(peakDebounceSamples,{'numeric'},{'scalar','integer','positive','>=',1,'<=',16});
                validateattributes(peakWindowSize,{'numeric'},{'scalar','integer','positive','>=',3,'<=',17});
                assert(mod(peakWindowSize,2)==1,'peakDetectionWindowSizeChannel0 must be an odd number');
                maskBefore = true(1,(peakWindowSize-1)/2);
                maskAfter  = true(1,(peakWindowSize-1)/2);
                photonIdxs = scanimage.components.scan2d.resscan.NI5771PhotonCounting.findPeaks(filtered,peakThreshold,maskBefore,maskAfter,peakDebounceSamples);
                
                histogram_ = zeros(numBinsHistogram,1);
                photonIdxs_ = mod(photonIdxs-1 + phase,numBinsHistogram) + 1;
                
                for phtIdx = 1:length(photonIdxs_)
                    histogram_(photonIdxs_(phtIdx)) = histogram_(photonIdxs_(phtIdx)) + 1;
                end                
            end
            
            function plotData(hFig,title_,threshold,data,denoised,filtered,photonIdxs,histogram_)
                if isempty(hFig)
                    hFig = figure;
                end
                
                hAx1 = subplot(3,1,1);
                plot(hAx1,0:(length(data)-1),data);
                title(hAx1,sprintf('%s\nRaw Data',title_));
                ylabel(hAx1,'ADC value');
                hAx2 = subplot(3,1,2);
                hold on;
                plot(hAx2,0:(length(filtered)-1),filtered);
                plot(hAx2,photonIdxs-1,filtered(photonIdxs),'ro');
                plot(hAx2,[0;(length(filtered)-1)],[threshold,threshold],'r--');
                
                phts = false(size(data));
                phts(photonIdxs) = true;
                
                title(hAx2,sprintf('Peak Detection, Mean= %e Var= %e',mean(phts),std(phts)^2));
                xlabel(hAx2,'Sample #');
                linkaxes([hAx1,hAx2],'x');
                hold off;
                hAx3 = subplot(3,1,3);
                hBarHist = bar(hAx3,0:(length(histogram_)-1),histogram_,...
                    'BarWidth',1,'LineStyle','none','FaceColor',most.idioms.vidrioBlue()); 
                title(hAx3,'Photon Histogram');
                xlabel(hAx3,'Sample #');
                ylabel(hAx3,'Photons');
                hAx3.XLim = [-0.5,(length(histogram_)-0.5)];
            end
        end
    end
    
    %% Property Access
    methods
        function set.autoApplyChanges(obj,val)
            validateattributes(val,{'numeric','logical'},{'scalar','binary'});
            obj.autoApplyChanges = val;
            obj.hDelayedEventListener.enabled = val;
            if val
                obj.propertyChanged();
            end
        end
        
        function set.filterCoefficientsChannel0(obj,val)
            if isempty(val)
                val = zeros(1,32);
                val(1) = 1;
            end
            val(end+1:32) = 0;            
            validateattributes(val,{'numeric'},{'vector','numel',32,'integer','>=',-2^29,'<',2^29});
            obj.filterCoefficientsChannel0 = val(:)';
            obj.propertyChanged();
        end
        
        function val = get.filterChannel0Delay(obj)
            val = getFilterDelay(obj.filterCoefficientsChannel0);
        end
        
        function set.filterCoefficientsChannel1(obj,val)
            if isempty(val)
                val = zeros(1,32);
                val(1) = 1;
            end
            val(end+1:32) = 0;
            validateattributes(val,{'numeric'},{'vector','numel',32,'integer','>=',-2^29,'<',2^29});
            obj.filterCoefficientsChannel1 = val(:)';
            obj.propertyChanged();
        end
        
        function val = get.filterChannel1Delay(obj)
            val = getFilterDelay(obj.filterCoefficientsChannel1);
        end
        
        function set.peakThresholdChannel0(obj,val)
            validateattributes(val,{'numeric'},{'scalar','integer','>=',-2^47,'<',2^47});
            obj.peakThresholdChannel0 = val;
            obj.propertyChanged();
        end
        
        function set.peakThresholdChannel1(obj,val)
            validateattributes(val,{'numeric'},{'scalar','integer','>=',-2^47,'<',2^47});
            obj.peakThresholdChannel1 = val;
            obj.propertyChanged();
        end
        
        function set.peakDetectionWindowSizeChannel0(obj,val)
            validateattributes(val,{'numeric'},{'scalar','integer','positive','>=',3,'<=',17});
            assert(mod(val,2)==1,'peakDetectionWindowSizeChannel0 must be an odd number');
            obj.peakDetectionWindowSizeChannel0 = val;
            obj.propertyChanged();
        end
        
        function set.peakDetectionWindowSizeChannel1(obj,val)
            validateattributes(val,{'numeric'},{'scalar','integer','positive','>=',3,'<=',17});
            assert(mod(val,2)==1,'peakDetectionWindowSizeChannel1 must be an odd number');
            obj.peakDetectionWindowSizeChannel1 = val;
            obj.propertyChanged();
        end
        
        function set.peakDebounceSamplesChannel0(obj,val)
            validateattributes(val,{'numeric'},{'scalar','integer','positive','>=',1,'<=',16});
            obj.peakDebounceSamplesChannel0 = val;
            obj.propertyChanged();
        end
        
        function set.peakDebounceSamplesChannel1(obj,val)
            validateattributes(val,{'numeric'},{'scalar','integer','positive','>=',1,'<=',16});
            obj.peakDebounceSamplesChannel1 = val;
            obj.propertyChanged();
        end
        
        function set.phaseChannel0(obj,val)
            validateattributes(val,{'numeric'},{'scalar','integer','nonnegative','<=',15});
            obj.phaseChannel0 = val;
            obj.propertyChanged();
        end
        
        function set.phaseChannel1(obj,val)
            validateattributes(val,{'numeric'},{'scalar','integer','nonnegative','<=',15'});
            obj.phaseChannel1 = val;
            obj.propertyChanged();
        end
        
        function set.rawDataScaleByPowerOf2Channel0(obj,val)
            validateattributes(val,{'numeric'},{'scalar','integer','nonnegative','<=',8});
            obj.rawDataScaleByPowerOf2Channel0 = val;
            obj.propertyChanged();
        end
        
        function set.rawDataScaleByPowerOf2Channel1(obj,val)
            validateattributes(val,{'numeric'},{'scalar','integer','nonnegative','<=',8});
            obj.rawDataScaleByPowerOf2Channel1 = val;
            obj.propertyChanged();
        end
        
        function set.staticNoiseChannel0(obj,val)
            if isempty(val)
                val = 0;
            end
            validateattributes(val,{'numeric'},{'vector','integer','>=',-2^15,'<',2^15});
            assert(length(val)<=128);
            assert(mod(128,length(val))==0);
            obj.staticNoiseChannel0 = val;
            obj.propertyChanged();
        end
        
        function set.staticNoiseChannel1(obj,val)
            if isempty(val)
                val = 0;
            end
            validateattributes(val,{'numeric'},{'vector','integer','>=',-2^15,'<',2^15});
            assert(length(val)<=128);
            assert(mod(128,length(val))==0);
            obj.staticNoiseChannel1 = val;
            obj.propertyChanged();
        end
        
        function set.differentiateChannel0(obj,val)
            validateattributes(val,{'numeric','logical'},{'scalar','binary'});
            obj.differentiateChannel0 = logical(val);
            obj.propertyChanged();
        end
        
        function set.differentiateChannel1(obj,val)
            validateattributes(val,{'numeric','logical'},{'scalar','binary'});
            obj.differentiateChannel1 = logical(val);
            obj.propertyChanged();
        end
    end
end

function val = getFilterDelay(filterCoefficients)
    impulse = zeros(size(filterCoefficients));
    impulse(1) = 1;
    y = filter(filterCoefficients,1,impulse);
    [~,idx] = max(y); % find first peak
    val = idx-1;
end

%--------------------------------------------------------------------------%
% PhotonDiscriminator.m                                                    %
% Copyright © 2016 Vidrio Technologies, LLC                                %
%                                                                          %
% ScanImage 2016 is premium software to be used under the purchased terms  %
% Code may be modified, but not redistributed without the permission       %
% of Vidrio Technologies, LLC                                              %
%--------------------------------------------------------------------------%
