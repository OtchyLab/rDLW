classdef PhotonCountingControls < most.Gui
    
    properties
        leftPanelWidth = 200;
        ch1CfgPnl;
        ch2CfgPnl;
    end
    
    %% LifeCycle
    methods
        function obj = PhotonCountingControls(hModel, hController)
            obj.hFig.CloseRequestFcn = @obj.figureCloseFcn;            
            obj.hFig.Units = 'pixels';
            
            obj.initializeGUI();
        end
        
        function initializeGUI(obj)
            
            obj.leftPanel = uipanel('Parent',obj.hFig,'Position',[10 10 obj.leftPanelWidth 100]);
            
            obj.Visible = 1;

            ch1CfgPnlWidth = 200;
            ch1CfgPnlHeight = 500;
            
            obj.ch1CfgPnl = uipanel('Parent',obj.hFig,...
                'FontSize',12,'Units','pixel','Position',[10 10 obj.leftPanelWidth obj.leftPanelHeight]);
                
                padding = 10;
                pos = ch1CfgPnlHeight-padding;
                hAx = axes()
            
            
         
hsp = uipanel('Parent',obj.leftPanel,'Title','Subpanel','FontSize',12,'Units','pixel',...
              'Position',[10 10 100 100]);
hbsp = uicontrol('Parent',hsp,'String','Push here','Units','pixel',...
              'Position',[18 18 72 36]);
        end
    end
    
    %% Internal Methods
    methods
        function figureCloseFcn(obj,src,evt)
            obj.Visible = 0;
        end
    end
end

%--------------------------------------------------------------------------%
% PhotonCountingControls.m                                                 %
% Copyright © 2016 Vidrio Technologies, LLC                                %
%                                                                          %
% ScanImage 2016 is premium software to be used under the purchased terms  %
% Code may be modified, but not redistributed without the permission       %
% of Vidrio Technologies, LLC                                              %
%--------------------------------------------------------------------------%
