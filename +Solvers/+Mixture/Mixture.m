classdef Mixture
    %MIXTURE Summary of this class goes here
    %   Detailed explanation goes here
    
     properties (SetAccess=?Solvers.Mixture.MixtureSolver)
        
        NZ           (1,1) double  {mustBeNumeric}                         = 0                    % [-] Number of axial steps
        NTIME        (1,1) double  {mustBeNumeric}                         = 0                    % [-] Number of time steps
        TIME         (1,1) double  {mustBeNumeric}                         = 0                    % [s] Time series
        DT           (1,1) double  {mustBeNumeric}                         = 0                    % [s] Time step size
        TIDX         (1,1) double  {mustBeNumeric}                         = 1                    % [-] Time step index
        Z            (:,1) double  {mustBeNumeric}                         = 1.                   % [m] Elevation
        DZ           (1,1) double  {mustBeNumeric}                         = 0                    % [m] Axial step size
        HFLUX        (:,:) double  {mustBeNumeric,mustBeNonnegative}       = 1.                   % [W/m^2] Wall heat flux

        W            (:,1) double  {mustBeNumeric}                         = 1.                   % [kg/s] Mass flow rate
        P            (:,1) double  {mustBeNumeric}                         = 7E6                  % [Pa] Pressure
        H            (:,1) double  {mustBeNumeric}                         = 1E6                  % [J/kg] Enthalpy
        DP           (1,1) struct                                                                 % [-] Detailed pressure drops
        ITR          (1,1) struct 

        inputSet    {isa(inputSet,'Inputs.InputSet')}
        boundaryConditions
        liquid
        vapor
        
        SOLVED      (1,1) logical                                          = true                 % Flag to indicate solved

    end
    
    

    methods
        function mix = Mixture(inputSet)
            %MIXTURE Creates a Mixture solver mix
            %   Detailed explanation goes here

            if nargin > 0
                % Store inputSet as object property
                mix.inputSet = inputSet;
            end

        end
        
        function mflux = MFLUX(mix, zIdx, tIdx)
        %MFLUX Mass flux [kg/m^2-s]
        %
            if nargin < 2, zIdx = 1:mix.NZ; end
            if nargin < 3, tIdx = 1:mix.NTIME; end

            mflux = mix.W(zIdx, tIdx)./mix.inputSet.geometry.AREA;
        end

        function xeq = XEQ(mix, zIdx, tIdx)
        %XEQ Equilibrium quality [-]
        %
            if nargin < 2, zIdx = 1:mix.NZ; end
            if nargin < 3, tIdx = 1:mix.NTIME; end
        
            xeq = (mix.H(zIdx, tIdx)-mix.inputSet.fluid.HF(tIdx).') ./ mix.inputSet.fluid.HFG(tIdx).';
        end

        function x = X(mix, zIdx, tIdx)
        %X Vapor quality [-]
        %
            if nargin < 2, zIdx = 1:mix.NZ; end
            if nargin < 3, tIdx = 1:mix.NTIME; end
        
            switch mix.inputSet.model.SCBOIL
                case 'NONE'
                    x=min(max(mix.XEQ(zIdx, tIdx),0),1);
            end
        end

        function vf =VF(mix, zIdx, tIdx)
        %VF Void fraction [-]
        %   
            if nargin < 2, zIdx = 1:mix.NZ; end
            if nargin < 3, tIdx = 1:mix.NTIME; end
            
            fluid = mix.inputSet.fluid;
            model = mix.inputSet.model;
            geom = mix.inputSet.geometry;

            switch model.VOID
                case 'HOMOGENEOUS'
                    % [-] Homogeneous void model
                    vf = vfslip(mix.X(zIdx, tIdx),1);
                case 'SLIP'
                    % [-] Slip void model
                    vf = vfslip(mix.X(zIdx, tIdx),model.SLIP);
                case 'BESTION'
                    % [-] Bestion drift flux model
                    C0 = 1.;                                               % [-] Distribution parameter
                    ugj = 0.188.*sqrt(model.G.*geom.HDIAM.*(fluid.RHOF(tIdx)-fluid.RHOG(tIdx))./fluid.RHOG(tIdx)); % [m/s] Drift velocity
                    vf = vfdrift(C0,ugj);            
            end
            
            
            function vf = vfslip(x,S)
            %VFSLIP Void fraction based on slip model
                vf = x.*fluid.RHOF(tIdx).'./(x.*fluid.RHOF(tIdx).'+S.*(1-x).*fluid.RHOG(tIdx).');
            end
            
            function vf = vfdrift(C0,ugj)
            %VFDRIFT Void fraction based on drift flux model
            % C0    [-]     Distribution parameter
            % ugj   [m/s]   Drift velocity
                vf  = mix.JG(zIdx, tIdx)./(C0.*(mix.JG(zIdx, tIdx)+mix.JL(zIdx, tIdx))+ugj);
            end
            
        end

        function rho = RHO(mix, zIdx, tIdx)
        %RHO Density [kg/m^3]
        %
            if nargin < 2, zIdx = 1:mix.NZ; end
            if nargin < 3, tIdx = 1:mix.NTIME; end
            
            fluid = mix.inputSet.fluid;
            rho = mix.VF(zIdx, tIdx).*fluid.RHOV(mix.H(zIdx, tIdx), tIdx)+ ...
                    (1-mix.VF(zIdx, tIdx)).*fluid.RHOL(mix.H(zIdx, tIdx), tIdx);
        end

        function mu = MU(mix, zIdx, tIdx)
        %MU Dynamic viscosity [Pa-s]
        %
            if nargin < 2, zIdx = 1:mix.NZ; end
            if nargin < 3, tIdx = 1:mix.NTIME; end
            
            fluid = mix.inputSet.fluid;
            mu = mix.X(zIdx, tIdx).*fluid.MUV(mix.H(zIdx, tIdx), tIdx) + ...
                    (1-mix.X(zIdx, tIdx)).*fluid.MUL(mix.H(zIdx, tIdx), tIdx);
        end

        function u = U(mix, zIdx, tIdx)
        %U Velocity [m/s]
        %
            if nargin < 2, zIdx = 1:mix.NZ; end
            if nargin < 3, tIdx = 1:mix.NTIME; end
            
            u = mix.W(zIdx, tIdx)./mix.RHO(zIdx, tIdx)./mix.inputSet.geometry.AREA; 
        end

        function jl = JL(mix, zIdx, tIdx)
        %JL Superfacial liquid velocity [m/s]
        %
            if nargin < 2, zIdx = 1:mix.NZ; end
            if nargin < 3, tIdx = 1:mix.NTIME; end
            
            fluid = mix.inputSet.fluid;
            jl = (1-mix.X(zIdx, tIdx)).*mix.MFLUX(zIdx, tIdx)./fluid.RHOL(mix.H(zIdx, tIdx), tIdx);
        end

        function jg = JG(mix, zIdx, tIdx)
        %JG Superfacial vapor velocity [m/s]
        %
            if nargin < 2, zIdx = 1:mix.NZ; end
            if nargin < 3, tIdx = 1:mix.NTIME; end
            
            fluid = mix.inputSet.fluid;
            jg = (1-mix.X(zIdx, tIdx)).*mix.MFLUX(zIdx, tIdx)./fluid.RHOV(mix.H(zIdx, tIdx), tIdx);
        end

        function re = RE(mix, zIdx, tIdx)
        %RE Reynolds number [-]
        %
            if nargin < 2, zIdx = 1:mix.NZ; end
            if nargin < 3, tIdx = 1:mix.NTIME; end
            
            re = 4.*mix.W(zIdx, tIdx)./mix.MU(zIdx, tIdx)./sum(mix.inputSet.geometry.PERIM);
        end

        function rel = REL(mix, zIdx, tIdx)
        %REL Liquid-equivalent Reynolds number [-]
        %
            if nargin < 2, zIdx = 1:mix.NZ; end
            if nargin < 3, tIdx = 1:mix.NTIME; end
            
            re = 4.*mix.W(zIdx, tIdx)./mix.MUL(zIdx, tIdx)./sum(mix.inputSet.geometry.PERIM);
        end

        function fw = FW(mix, zIdx, tIdx)
        %FW Wall friction factor [-]
        %
            if nargin < 2, zIdx = 1:mix.NZ; end
            if nargin < 3, tIdx = 1:mix.NTIME; end
            
            model = mix.inputSet.model;
            fw = model.FRICTION(1).*mix.RE(zIdx, tIdx).^model.FRICTION(2)+model.FRICTION(3);
        end

        function tauw = TAUW(mix, zIdx, tIdx)
        %TAUW wall shear stress [Pa]
        %
            if nargin < 2, zIdx = 1:mix.NZ; end
            if nargin < 3, tIdx = 1:mix.NTIME; end
            
            tauw = 0.5.*(mix.FW(zIdx, tIdx)./4)./mix.RHO(zIdx, tIdx).*(mix.W(zIdx, tIdx)./mix.inputSet.geometry.AREA).^2;
        end

        function kloss = KLOSS(mix, zIdx)
        %KLOSS Local pressure loss coefficient [-]
        % TODO: NEED TO BE VERIFIED
            if nargin < 2, zIdx = 1:mix.NZ; end
            
            model = mix.inputSet.model;

            kloss = zeros(length(mix.Z),1);                                 % [-] Initialize local loss coefficient array to 0
            [~,ind]=min(abs(mix.Z-model.KLOC));                             % Find local loss elevation indexes (closest node)
            kloss(ind)=model.KLOSS;                                         % [-] Apply loss
            kloss = kloss(zIdx).';                                            % [-] Restrict to selected nodes
            
        end

        function dpk = DPK(mix, zIdx, tIdx)
        %DPK Local pressure loss [Pa]
        %
            if nargin < 2, zIdx = 1:mix.NZ; end
            if nargin < 3, tIdx = 1:mix.NTIME; end
            
            dpk = 0.5.*mix.KLOSS(zIdx)./mix.RHO(zIdx, tIdx).*(mix.W(zIdx, tIdx)./mix.inputSet.geometry.AREA).^2;
        end

        function t = T(mix, zIdx, tIdx)
        %T Temperature [K]
        %
            if nargin < 2, zIdx = 1:mix.NZ; end
            if nargin < 3, tIdx = 1:mix.NTIME; end
            
            t = mix.inputSet.fluid.T(mix.H(zIdx, tIdx), tIdx);
        end
        
        function plotz(mix, tIdx)
        %PLOTZ
        %
        arguments
            mix
            tIdx (1,1) double
        end
            figure('name',['Axial distributions of mixture parameters at ' num2str(mix.TIME(tIdx)) ' [s]'])
                
            nexttile; hold all; grid on;
            plot(mix.Z,mix.W(:, tIdx),'.-')
            plot(mix.liquid.Z,mix.liquid.W(:, tIdx),'.-')
            plot(mix.vapor.Z,mix.vapor.W(:, tIdx),'.-')
            xlabel('Axial position [m]'); xlim(mix.Z([1 end]));
            ylabel('Mass flowrates [kg/s]')
            legend({'Mixture','Liquid','Vapor'},'location','southEast')
            set(gca,'fontSize',14)
            
            nexttile; hold all; grid on;
            plot(mix.Z,cumsum(mix.DP.Tot(:,tIdx)),'.-')
            plot(mix.Z,cumsum(mix.DP.Grav(:,tIdx)),'.-')
            plot(mix.Z,cumsum(mix.DP.Wall(:,tIdx)),'.-')
            plot(mix.Z,cumsum(mix.DP.Acc_z(:,tIdx)),'.-')
            plot(mix.Z,cumsum(mix.DP.Acc_t(:,tIdx)),'.-')
            plot(mix.Z,cumsum(mix.DP.K(:,tIdx)),'.-')
            xlabel('Axial position [m]'); xlim(mix.Z([1 end]));
            ylabel('Pressure drop [Pa]')
            legend({'Total','Gravitational','Wall','Acc z','Acc t','Local'},'location','northWest');
            set(gca,'fontSize',14)
            
            nexttile; hold all; grid on;
            plot(mix.Z,mix.XEQ(1:mix.NZ,tIdx),'.-')
            plot(mix.Z,mix.X(1:mix.NZ,tIdx),'.-')
            plot(mix.Z,mix.VF(1:mix.NZ,tIdx),'.-')
            xlabel('Axial position [m]'); xlim(mix.Z([1 end]));
            ylabel('Quality / Void fraction [-]')
            legend({'Equilibrium quality','Vapor mass quality','Void fraction'},'location','southEast')
            set(gca,'fontSize',14)
            
            nexttile; hold all; grid on;
            plot(mix.Z,mix.U(1:mix.NZ,tIdx),'.-')
            plot(mix.liquid.Z,mix.liquid.U(1:mix.NZ,tIdx),'.-')
            plot(mix.vapor.Z,mix.vapor.U(1:mix.NZ,tIdx),'.-')
            xlabel('Axial position [m]'); xlim(mix.Z([1 end]));
            ylabel('Velocities [m/s]')
            legend({'Mixture','Liquid','Vapor'},'location','southEast')
            set(gca,'fontSize',14)

        end
    
        function plott(mix, zIdx)
            %PLOTT 
            %
            arguments
                mix
                zIdx (:,1) double
            end

            figure('name',['Time series of mixture parameters at ' num2str(mix.Z(zIdx(1))) ' [m]']);
            
            timeplot('W','Mass flowrates [kg/s]')
            timeplot('P','Pressure [Pa]')
            timeplot('XEQ','Equilibrium quality [-]')
            timeplot('X','Steam mass quality [-]')
            timeplot('VF','Void fraction [-]')
            timeplot('U','Velocity [m/s]')

            function timeplot(param,ylabelText)

                nexttile; hold all; grid on;
                if ismethod(mix,param)
                    plot(mix.TIME,mix.(param)(zIdx),'.-');
                else
                    plot(mix.TIME,mix.(param)(zIdx,:),'.-');
                end
                legendStr = num2str(mix.Z(zIdx),'z=%0.4f m');
                legend(legendStr,'Location','southeast');
                
                xlabel('Time [s]'); xlim([mix.TIME([1 end])]);
                ylabel(ylabelText)
                set(gca,'fontSize',14)
            
            end

        end
        
        function interpOut = timeInterpolate(mix, y)
            interpOut = interp1([mix.inputSet.bc.TIME], ...
                                y, ...
                                mix.TIME, ...
                                mix.inputSet.options.TIMEINTERP);
        end

        function interpOut = axialInterpolate(mix, x, y)
            interpOut = interp1(x, ...
                                y, ...
                                mix.Z, ...
                                mix.inputSet.options.AXIALINTERP, ...
                                "extrap");
        end
    end
end

