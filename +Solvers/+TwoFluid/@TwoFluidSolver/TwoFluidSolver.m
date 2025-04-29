classdef TwoFluidSolver < Solvers.AbstractSolver
    %TWOFLUIDSOLVER Summary of this class goes here
    %   Detailed explanation goes here
    
     properties (SetAccess=protected)
        
        NZ           (1,1) double  {mustBeNumeric}                          = 0         % [-] Number of axial steps
        NTIME        (1,1) double  {mustBeNumeric}                          = 0         % [-] Number of time steps
        TIME         (:,1) double  {mustBeNumeric}                          = 0         % [s] Time series
        DT           (1,1) double  {mustBeNumeric}                          = 0         % [s] Time step size
        Z            (:,1) double  {mustBeNumeric}                          = 1.        % [m] Elevation
        DZ           (1,1) double  {mustBeNumeric}                          = 0         % [m] Axial step size

        fluid       {isa(fluid,'Inputs.FluidProperties')}
        boundaryConditions
        
        liquidInit
        vaporInit
        fluidInit
        liquid
        vapor

     end

     properties (SetAccess = protected)
        mixSolver
        inputSet
        STATE                                                               = Solvers.SolverState.UNSOLVED
     end


    methods
        solve(twfSolver)
    end

    methods
        function twfSolver = TwoFluidSolver(inputSet,mixSolver)
            %TWOFLUIDSOLVER Creates a TwoFluid solver
            %   Detailed explanation goes here
            arguments
                inputSet            {isa(inputSet,'Inputs.InputSet')}
                mixSolver           {isa(mixSolver,'Solvers.Mixture.MixtureSolver')} = Solvers.Mixture.MixtureSolver(inputSet)
            end

            % Call abstract class constructor
            twfSolver = twfSolver@Solvers.AbstractSolver(inputSet);
            
            % Store mixSolver handle
            twfSolver.mixSolver = mixSolver;

            % Attempt to solve mixSolver if it is unsolved
            if twfSolver.mixSolver.STATE == Solvers.SolverState.UNSOLVED
                twfSolver.mixSolver.solve();
            end
            
            % Initialize solver parameters
            twfSolver.initializeSolver();

        end
        
        function initializeSolver(twfSolver)
        %INITIALIZESOLVER Initialize solver using the stored inputSet
        %
            
            import Inputs.*
            import Solvers.TwoFluid.*
            import Solvers.*

            % Copy relevant properties from mixSolver
            props = {'NZ','NTIME','TIME','DT','Z','DZ','fluid','boundaryConditions'}; % mixSolver properties
            for p = props
                twfSolver.(p{:}) = twfSolver.mixSolver.(p{:});
            end

            % Local parameters
            mixArr = twfSolver.mixSolver.mixture;                           % Mixture solution
            %model  = twfSolver.inputSet.model;                              % Models
            %geom   = twfSolver.inputSet.geometry;                           % Geometry

            % Setup inner iteration value struct
            ITRFields = ["N","DW","DU","DH"];
            ITRl = twfSolver.CreateITR(twfSolver.NZ, ITRFields);
            ITRFields = ["N","DW","DU","DH"];
            ITRv = twfSolver.CreateITR(twfSolver.NZ, ITRFields);

            % Create liquid and vapor arrays (by timestep)
            liqArr(twfSolver.NTIME) = Liquid();
            vapArr(twfSolver.NTIME) = Vapor();
            props = {'NZ','Z','NTIME','DT','TIME','TIDX','inputSet','fluid'};  % liquid and vapor properties
            
            for tIdx = 1:twfSolver.NTIME

                % Convenience variables (handles)
                liq         = liqArr(tIdx);
                vap         = vapArr(tIdx);
                mix         = mixArr(tIdx);
                fluid       = twfSolver.fluid(tIdx);
                
                % Inputset, fluid                
                liq.inputSet = twfSolver.inputSet;
                liq.fluid    = fluid;
                
                % Axial Steps
                vap.DZ = twfSolver.DZ;
                
                liq.NZ = twfSolver.NZ;
                liq.DZ = twfSolver.DZ;
                liq.Z  = twfSolver.Z;
                
                % Time step
                liq.NTIME = twfSolver.NTIME;
                liq.DT    = twfSolver.DT;
                liq.TIME  = twfSolver.TIME(tIdx);
                liq.TIDX  = tIdx;
                
                % Copy properties to vapor
                for p = props
                    vap.(p{:}) = liq.(p{:});
                end
                
                % Initialize mixture
                liq.mix = Mixture(mix,liq,vap);
                vap.mix = liq.mix;
                
                % Initialize Mass flow rates [kg/s] based on phase mass exchange only
                % Note: only 1st time step is important since other time steps are initialized by the previous time step in the solver
                liq.W = mix.liquid.W;                                      % [kg/s] Mixture model liquid mass flow rate
                vap.W = mix.vapor.W;                                       % [kg/s] Mixture model vapor mass flow rate
                
                % Initialize velocity [m/s]
                liq.U = mix.liquid.U;                                      % [m/s] Mixture model liquid velocity
                vap.U = mix.vapor.U;                                       % [m/s] Mixture model vapor velocity
               
                % Initialize enthalpy [J/kg]
                liq.H = min(mix.H,fluid.HF);                               % [J/kg] Mixture model enthalpy, up to liquid saturation
                vap.H = max(mix.H,fluid.HG);                               % [J/kg] Mixture model enthalpy, down to vapor saturation
                
                % ITR
                liq.ITR = ITRl;
                vap.ITR = ITRv;

            end

            % Store transient mixture array
            twfSolver.liquid = liqArr;
            twfSolver.vapor  = vapArr;

            % Create steady state mixture array
            twfSolver.liquidInit = copy( ...
                repmat(liqArr(1),1,twfSolver.inputSet.options.SSMAXITER));
            twfSolver.vaporInit  = copy( ...
                repmat(vapArr(1),1,twfSolver.inputSet.options.SSMAXITER));
            twfSolver.fluidInit  = FluidProperties( ...
                                    twfSolver.boundaryConditions.PRESSURE(1), ...
                                    twfSolver.inputSet.model);

            % Update liquidInit and vaporInit times and timesteps
            initTIMEDT = twfSolver.inputSet.options.SSTSTEP;
            initNTIME  = length(twfSolver.liquidInit);
            initTIME   = 0:initTIMEDT:initTIMEDT*(initNTIME-1);
            initTIDX   = 1:length(twfSolver.liquidInit);

            for i = 1:length(twfSolver.liquidInit)
                twfSolver.liquidInit(i).TIME  = initTIME(i);
                twfSolver.liquidInit(i).DT    = initTIMEDT;
                twfSolver.liquidInit(i).NTIME = initNTIME;
                twfSolver.liquidInit(i).TIDX  = initTIDX(i);

                twfSolver.vaporInit(i).TIME   = initTIME(i);
                twfSolver.vaporInit(i).DT     = initTIMEDT;
                twfSolver.vaporInit(i).NTIME  = initNTIME;
                twfSolver.vaporInit(i).TIDX   = initTIDX(i);
            end

            % set STATE to UNSOLVED
            twfSolver.STATE = SolverState.UNSOLVED;

        end

        function plotter = plotz(twfSolver, tIdx, opt)
        %PLOTZ
        %   NOTE: currently supports only single timeSteps
            arguments
                twfSolver
                tIdx          (1,1) double {mustBeScalarOrEmpty,mustBeInteger,mustBePositive}                                  = 1
                opt.display   {mustBeMember(opt.display,{'HFLUX','W','U','H','VR','T','INTAREA','REGIME','PWE','PME','PEE','ALL'})} = {'HFLUX','W','U','H','VR'}
                opt.solveMode {mustBeMember(opt.solveMode,{'TRANSIENT','STEADY'})}                                             = 'TRANSIENT'
                opt.wall      (1,:) double {mustBeVector,mustBeInteger,mustBePositive}                                         = 1:twfSolver.inputSet.geometry.NWALL
                opt.zIdx      (:,1) double {mustBeVector,mustBeInteger,mustBePositive}                                         = 1:twfSolver.NZ
                opt.unitTemp  {mustBeMember(opt.unitTemp,{'K','C'})}                                                           = 'K'
            end
            
            if isempty(opt.wall), opt.wall = 1:twfSolver.inputSet.geometry.NWALL; end
            if length(opt.zIdx) < 2
                twfSolver.log('Error: At least 2 axial indexes required to plot axial distributions.\n');
                return
            end
            
            z     = twfSolver.Z(opt.zIdx);
            bc    = twfSolver.boundaryConditions;
            model = twfSolver.inputSet.model;
            
            switch opt.solveMode
                case 'TRANSIENT'
                    liq = twfSolver.liquid(tIdx);
                    vap = twfSolver.vapor(tIdx);
                case 'STEADY'
                    liq = twfSolver.liquidInit(tIdx);
                    vap = twfSolver.vaporInit(tIdx);
                    tIdx = 1;
            end
            
            dTemp = 0; if strcmp(opt.unitTemp,'C'), dTemp = -273.15; end
            
            %mix0 = twfSolver.mixSolver.mixture(tIdx);
            mix  = liq.mix;
            bcHFLUX = bc.HFLUX(opt.zIdx,:,tIdx);
            
            plotter = Solvers.SolverPlotter( ...
                                sprintf('Axial distributions of two-field parameters at %0.3f [s] - %s', liq.TIME, opt.solveMode), ...
                                opt.wall);
            plotter.setZs(z);
            
            % Wall heat flux
            if any(ismember({'HFLUX','ALL'},opt.display))
                plotter.newTile( ...
                    'tileTitle',         'Wall heat flux', ...
                    'xlabel'   ,     'Axial position [m]', ...
                    'ylabel'   , 'Wall heat flux [W/m^2]');
                plotter.plotz(  bcHFLUX                     ,'bc'         ,'DisplayName','Boundary Condition');
                plotter.plotz(mix.HFLUX(opt.zIdx)           ,'Mixture'                                       );
                plotter.plotz(liq.HFLUX(opt.zIdx)           ,'Liquid'                                        );
                plotter.plotz(vap.HFLUX(opt.zIdx)           ,'Vapor'                                         );
                plotter.plotz(vap.HFLUXWALEVAP(liq,opt.zIdx),'Evaporation','DisplayName','Wall evaporation'  );
                if ~strcmp(model.CBT,'NONE')
                    plotter.plotz(mix.CHF(opt.zIdx)         ,'CHF'                                           );
                end
                plotter.legend('show', 'Location', 'best');
            end
            
            % Mass flow rates
            if any(ismember({'W','ALL'},opt.display))
                plotter.newTile( ...
                    'tileTitle', 'Phase mass flow rates', ...
                    'xlabel',       'Axial position [m]', ...
                    'ylabel',    'Mass flow rate [kg/s]');
                %plotter.plotz(mix0.W(opt.zIdx),'Mixture');
                plotter.plotz(mix.W(opt.zIdx) ,'Mixture');
                plotter.plotz(liq.W(opt.zIdx) ,'Liquid' );
                plotter.plotz(vap.W(opt.zIdx) ,'Vapor'  );
                plotter.legend('show', 'Location', 'best');
            end
            
            % Phase velocities
            if any(ismember({'U','ALL'},opt.display))
                plotter.newTile( ...
                    'tileTitle',   'Phase velocities', ...
                    'xlabel'   , 'Axial position [m]', ...
                    'ylabel'   ,     'Velocity [m/s]');
                %plotter.plotz(mix0.U(opt.zIdx),'Mixture');
                plotter.plotz(mix.U(opt.zIdx) ,'Mixture');
                plotter.plotz(liq.U(opt.zIdx) ,'Liquid' );
                plotter.plotz(vap.U(opt.zIdx) ,'Vapor'  );
                plotter.legend('show', 'Location', 'best');
            end
            
            % Phase enthalpies
            if any(ismember({'H','ALL'},opt.display))
                plotter.newTile( ...
                    'tileTitle',   'Phase enthalpies', ...
                    'xlabel'   , 'Axial position [m]', ...
                    'ylabel'   ,    'Enthalpy [J/kg]');
                
                %plotter.plotz(mix0.H(opt.zIdx),'Mixture');
                plotter.plotz(mix.H(opt.zIdx) ,'Mixture');
                plotter.plotz(liq.H(opt.zIdx) ,'Liquid' );
                plotter.plotz(vap.H(opt.zIdx) ,'Vapor'  );
                plotter.plotz(repmat(twfSolver.fluid(tIdx).HF,twfSolver.NZ,1),'SatLiq','DisplayName','Sat liquid');
                plotter.plotz(repmat(twfSolver.fluid(tIdx).HG,twfSolver.NZ,1),'SatVap','DisplayName','Sat vapor');
                plotter.legend('show', 'Location', 'best');
            end
            
            % Vapor ratios (void fraction and qualities)
            if any(ismember({'VR','ALL'},opt.display))
                plotter.newTile( ...
                    'tileTitle', 'Void fractions and qualities', ...
                    'xlabel'   ,           'Axial position [m]', ...
                    'ylabel'   ,  'Quality / Void fraction [-]');
                %plotter.plotz(mix0.XEQ(opt.zIdx)  ,'Equil'       ,'DisplayName','Equilibrium quality')
                plotter.plotz(mix.XEQ(opt.zIdx)   ,'Equil'       ,'DisplayName','Equilibrium quality')
                plotter.plotz(vap.X(opt.zIdx)     ,'Vapor'       ,'DisplayName','Vapor mass quality' )
                plotter.plotz(vap.VF(liq,opt.zIdx),'VoidFraction','DisplayName','Void fraction'      )
                plotter.legend('show', 'Location', 'best');
            end
            
            % Phase temperatures
            if any(ismember({'T','ALL'},opt.display))
                plotter.newTile( ...
                    'tileTitle',              'Phase temperatures', ...
                    'xlabel'   ,              'Axial position [m]', ...
                    'ylabel'   , ['Temperature [' opt.unitTemp ']']);
                
                plotter.plotz(liq.T(opt.zIdx)+dTemp,'Liquid');
                plotter.plotz(vap.T(opt.zIdx)+dTemp, 'Vapor');
                plotter.plotz(repmat(twfSolver.fluid(tIdx).TSAT,twfSolver.NZ,1)+dTemp,'Saturation');
                plotter.legend('show', 'Location', 'best');
            end
            
            % Vapor and liquid mass exchanges
            if any(ismember({'PWE','ALL'},opt.display))
                ah_vap = plotter.newTile( ...
                    'tileTitle', 'Vapor mass exchanges', ...
                    'xlabel',      'Axial position [m]', ...
                    'ylabel',  'Mass exchange [kg/s/m]');
                plotter.plotz(vap.MWALEVAP(liq,opt.zIdx),'Evaporation'    ,'DisplayName','Wall evaporation'        );
                plotter.plotz(vap.MINTEVAP(liq,opt.zIdx),'InterfacialEvap','DisplayName','Interfacial evaporation' );
                plotter.plotz(vap.MINTCOND(liq,opt.zIdx),'InterfacialCond','DisplayName','Interfacial condensation');
                plotter.plotz(vap.MTOT(liq,opt.zIdx)    ,'Total'                                                   );
                plotter.legend('show', 'Location', 'best');
                ymax = max(arrayfun(@(x) max(abs(x.YLim)),plotter.gca))+1E-6;
                plotter.ylim([-ymax ymax]);
                
                ah_liq = plotter.newTile( ...
                    'tileTitle', 'Liquid mass exchanges', ...
                    'xlabel',       'Axial position [m]', ...
                    'ylabel',   'Mass exchange [kg/s/m]');
                plotter.plotz(liq.MWALEVAP(vap,opt.zIdx),'Evaporation'    ,'DisplayName','Wall evaporation'        );
                plotter.plotz(liq.MINTEVAP(vap,opt.zIdx),'InterfacialEvap','DisplayName','Interfacial evaporation' );
                plotter.plotz(liq.MINTCOND(vap,opt.zIdx),'InterfacialCond','DisplayName','Interfacial condensation');
                plotter.plotz(liq.MTOT(vap,opt.zIdx)    ,'Total'                                                   );
                plotter.legend('show', 'Location', 'best');
                ymax = max(arrayfun(@(x) max(abs(x.YLim)),plotter.gca))+1E-6;
                plotter.ylim([-ymax ymax]);
                
                % Link exchange axes
                % TODO: this can be a plotter method
                for wallIdx = 1:length(ah_liq)
                    linkaxes([ah_vap(wallIdx), ah_liq(wallIdx)]);
                end
            end
            
            % Vapor and liquid momentum Exchanges
            if any(ismember({'PME','ALL'},opt.display))
                ah_vap = plotter.newTile( ...
                    'tileTitle', 'Vapor momentum exchanges', ...
                    'xlabel',          'Axial position [m]', ...
                    'ylabel',          'Shear stress [N/m]');
                plotter.plotz(vap.FWALL(liq,opt.zIdx)   ,'Wall'           ,'DisplayName','Wall shear'             );
                plotter.plotz(vap.FDRAG(liq,opt.zIdx)   ,'Interfacial'    ,'DisplayName','Interfacial shear'      );
                plotter.plotz(vap.FBUOY(liq,opt.zIdx)   ,'Buoyancy'                                               );
                plotter.plotz(vap.FGRAV(liq,opt.zIdx)   ,'Gravity'                                                );
                plotter.plotz(vap.FWALEVAP(liq,opt.zIdx),'Evaporation'    ,'DisplayName','Wall evaporation'       );
                plotter.plotz(vap.FINTEVAP(liq,opt.zIdx),'InterfacialEvap','DisplayName','Interfacial evaporation');
                plotter.plotz(vap.FTOT(liq,opt.zIdx)    ,'Total'                                                  );
                plotter.legend('show', 'Location', 'best');
                ymax = max(arrayfun(@(x) max(abs(x.YLim)),plotter.gca))+1E-6;
                plotter.ylim([-ymax ymax]);
                
                ah_liq = plotter.newTile( ...
                    'tileTitle', 'Liquid momentum exchanges', ...
                    'xlabel',           'Axial position [m]', ...
                    'ylabel',           'Shear stress [N/m]');
                plotter.plotz(liq.FWALL(vap,opt.zIdx)   ,'Wall'           ,'DisplayName','Wall shear'              );
                plotter.plotz(liq.FDRAG(vap,opt.zIdx)   ,'Interfacial'    ,'DisplayName','Interfacial shear'       );
                plotter.plotz(liq.FBUOY(vap,opt.zIdx)   ,'Buoyancy'                                                );
                plotter.plotz(liq.FGRAV(vap,opt.zIdx)   ,'Gravity'                                                 );
                plotter.plotz(liq.FINTCOND(vap,opt.zIdx),'InterfacialCond','DisplayName','Interfacial condensation');
                plotter.plotz(liq.FTOT(vap,opt.zIdx)    ,'Total'                                                   );
                plotter.legend('show', 'Location', 'best');
                ymax = max(arrayfun(@(x) max(abs(x.YLim)),plotter.gca))+1E-6;
                plotter.ylim([-ymax ymax]);
                
                % Link exchange axes
                % TODO: this can be a plotter method
                for wallIdx = 1:length(ah_liq)
                    linkaxes([ah_vap(wallIdx), ah_liq(wallIdx)]);
                end
            end
            
            % Vapor and liquid energy Exchanges
            if any(ismember({'PEE','ALL'},opt.display))
                ah_vap = plotter.newTile( ...
                    'tileTitle', 'Vapor energy exchanges', ...
                    'xlabel',        'Axial position [m]', ...
                    'ylabel',     'Energy transfer [W/m]');
                plotter.plotz(vap.HWALHEAT(opt.zIdx)    ,'Wall'                                                    );
                plotter.plotz(vap.HWALEVAP(liq,opt.zIdx),'Evaporation'    ,'DisplayName','Wall evaporation'        );
                plotter.plotz(vap.HINTEVAP(liq,opt.zIdx),'InterfacialCond','DisplayName','Interfacial evaporation' );
                plotter.plotz(vap.HINTCOND(liq,opt.zIdx),'InterfacialEvap','DisplayName','Interfacial condensation');
                plotter.plotz(vap.HTOT(liq,opt.zIdx)    ,'Total'                                                   );
                plotter.legend('show', 'Location', 'best');
                ymax = max(arrayfun(@(x) max(abs(x.YLim)),plotter.gca))+1E-6;
                plotter.ylim([-ymax ymax]);
                
                ah_liq = plotter.newTile( ...
                    'tileTitle', 'Liquid energy exchanges', ...
                    'xlabel',         'Axial position [m]', ...
                    'ylabel',      'Energy transfer [W/m]');
                plotter.plotz(liq.HWALHEAT(opt.zIdx)    ,'Wall'                                                    );
                plotter.plotz(liq.HWALEVAP(vap,opt.zIdx),'Evaporation'    ,'DisplayName','Wall evaporation'        );
                plotter.plotz(liq.HINTEVAP(vap,opt.zIdx),'InterfacialCond','DisplayName','Interfacial evaporation' );
                plotter.plotz(liq.HINTCOND(vap,opt.zIdx),'InterfacialEvap','DisplayName','Interfacial condensation');
                plotter.plotz(liq.HTOT(vap,opt.zIdx)    ,'Total'                                                   );
                plotter.legend('show', 'Location', 'best');
                ymax = max(arrayfun(@(x) max(abs(x.YLim)),plotter.gca))+1E-6;
                plotter.ylim([-ymax ymax]);
                
                % Link exchange axes
                % TODO: this can be a plotter method
                for wallIdx = 1:length(ah_liq)
                    linkaxes([ah_vap(wallIdx), ah_liq(wallIdx)]);
                end
            end
            
             % Volumetric interfacial area
            if any(ismember({'INTAREA','ALL'},opt.display))
                plotter.newTile( ...
                    'tileTitle', 'Volumetric interfacial area', ...
                    'xlabel'   ,          'Axial position [m]', ...
                    'ylabel'   ,    'Interfacial area [m^-^1]');
                plotter.plotz(liq.INTAREA(vap,opt.zIdx),'Interfacial')
            end
            
            % Two-phase flow regimes
            if any(ismember({'REGIME','ALL'},opt.display))
                plotter.newTile( ...
                    'tileTitle', 'Two-phase flow regimes', ...
                    'xlabel'   ,     'Axial position [m]');
                plotter.plotz(liq.FLOWREGIME(opt.zIdx),'Interfacial')
                labels = strrep(cellstr(unique(liq.FLOWREGIME)),'_',' ');
                plotter.ylabels(labels);
                plotter.ylim([0 length(labels)+1]);
            end

        end
        
        function plotter = plott(twfSolver, zIdx, opt)
        %PLOTT
        %   NOTE: currently supports only single elevation
            arguments
                twfSolver
                zIdx            (1,1) double {mustBeScalarOrEmpty,mustBeInteger,mustBePositive}                                  = twfSolver.NZ
                opt.display     {mustBeMember(opt.display,{'HFLUX','W','U','H','VR','T','INTAREA','REGIME','PWE','PME','PEE','ALL'})} = {'HFLUX','W','U','H','VR'}
                opt.solveMode   {mustBeMember(opt.solveMode,{'TRANSIENT','STEADY'})}                                             = 'TRANSIENT'
                opt.wall        (1,:) double {mustBeVector,mustBeInteger,mustBePositive}                                         = 1:twfSolver.inputSet.geometry.NWALL
                opt.tIdx        (:,1) double {mustBeVector,mustBeInteger,mustBePositive}                                         = 1:twfSolver.NTIME
                opt.reverseTime (1,1) logical                                                                                    = false
                opt.unitTemp    {mustBeMember(opt.unitTemp,{'K','C'})}                                                           = 'K'
            end
            
            if isempty(opt.wall), opt.wall = 1:twfSolver.inputSet.geometry.NWALL; end
            
            model = twfSolver.inputSet.model;
            
            switch opt.solveMode
                case 'TRANSIENT'
                    mix = twfSolver.mixSolver.mixture(opt.tIdx);
                    fld = twfSolver.mixSolver.fluid(opt.tIdx);
                    liq = twfSolver.liquid(opt.tIdx);
                    vap = twfSolver.vapor(opt.tIdx);
                    bcHFLUX = permute(twfSolver.boundaryConditions.HFLUX(zIdx,:,:),[3 2 1]);
                case 'STEADY'
                    if isequal(opt.tIdx,[1:twfSolver.NTIME]')
                        opt.tIdx = 1:length(twfSolver.liquidInit);
                    end
                    %mix = twfSolver.mixSolver.mixtureInit(opt.tIdx);
                    fld = repmat(twfSolver.mixSolver.fluid(1),1,length(opt.tIdx));
                    liq = twfSolver.liquidInit(opt.tIdx);
                    vap = twfSolver.vaporInit(opt.tIdx);
                    bcHFLUX = repmat(twfSolver.boundaryConditions.HFLUX(zIdx,:,1),length(opt.tIdx),1);
            end
            
            time = [liq.TIME];
            if length(time) < 2
                twfSolver.log('Error: At least 2 time indexes required to plot time series.\n');
                return
            end
            if opt.reverseTime
                time = time -time(end);
            end
            
            dTemp = 0; if strcmp(opt.unitTemp,'C'), dTemp = -273.15; end

            z = twfSolver.Z;
            plotter = Solvers.SolverPlotter( ...
                                sprintf('Time distributions of two-fluid parameters at %0.3f [m] - %s', z(zIdx), opt.solveMode), ...
                                opt.wall);
            plotter.setZs(time);
            
            % Wall heat flux
            if any(ismember({'HFLUX','ALL'},opt.display))
                plotter.newTile( ...
                    'tileTitle',         'Wall heat flux', ...
                    'xlabel'   ,               'Time [s]', ...
                    'ylabel'   , 'Wall heat flux [W/m^2]');
                plotter.plotz(             bcHFLUX                          ,'bc'         ,'DisplayName','Boundary Condition');
                plotter.plotz(liq.transient('mix.HFLUX'   ,    'zIdx',zIdx)','Mixture'                                       );
                plotter.plotz(liq.transient('HFLUX'       ,    'zIdx',zIdx)','Liquid'                                        );
                plotter.plotz(vap.transient('HFLUX'       ,    'zIdx',zIdx)','Vapor'                                         );
                plotter.plotz(vap.transient('HFLUXWALEVAP',liq,'zIdx',zIdx)','Evaporation','DisplayName','Wall evaporation'  );
                if ~strcmp(model.CBT,'NONE')
                    plotter.plotz(liq.transient('mix.CHF'     ,    'zIdx',zIdx)','CHF'                                           );
                end
                plotter.legend('show', 'Location', 'best');
            end
            
            % Mass flow rates
            if any(ismember({'W','ALL'},opt.display))
                plotter.newTile( ...
                    'tileTitle', 'Phase mass flow rates', ...
                    'xlabel',                 'Time [s]', ...
                    'ylabel',    'Mass flow rate [kg/s]');
                %plotter.plotz(mix.transient('W'    ,'zIdx',zIdx)','Mixture');
                plotter.plotz(liq.transient('mix.W','zIdx',zIdx)','Mixture');
                plotter.plotz(liq.transient('W'    ,'zIdx',zIdx)','Liquid' );
                plotter.plotz(vap.transient('W'    ,'zIdx',zIdx)','Vapor'  );
                plotter.legend('show', 'Location', 'best');
            end
            
            % Phase velocities
            if any(ismember({'U','ALL'},opt.display))
                plotter.newTile( ...
                    'tileTitle',   'Phase velocities', ...
                    'xlabel'   ,           'Time [s]', ...
                    'ylabel'   ,     'Velocity [m/s]');
                %plotter.plotz(mix.transient('U'    ,'zIdx',zIdx)','Mixture');
                plotter.plotz(liq.transient('mix.U','zIdx',zIdx)','Mixture');
                plotter.plotz(liq.transient('U'    ,'zIdx',zIdx)','Liquid' );
                plotter.plotz(vap.transient('U'    ,'zIdx',zIdx)','Vapor'  );
                plotter.legend('show', 'Location', 'best');
            end
            
            % Phase enthalpies
            if any(ismember({'H','ALL'},opt.display))
                plotter.newTile( ...
                    'tileTitle',   'Phase enthalpies', ...
                    'xlabel'   ,           'Time [s]', ...
                    'ylabel'   ,    'Enthalpy [J/kg]');
                
                %plotter.plotz(mix.transient('H'    ,'zIdx',zIdx)','Mixture'                           );
                plotter.plotz(liq.transient('mix.H','zIdx',zIdx)','Mixture'                           );
                plotter.plotz(liq.transient('H'    ,'zIdx',zIdx)','Liquid'                            );
                plotter.plotz(vap.transient('H'    ,'zIdx',zIdx)','Vapor'                             );
                plotter.plotz(fld.transient('HF')'               ,'SatLiq' ,'DisplayName','Sat liquid');
                plotter.plotz(fld.transient('HG')'               ,'SatVap' ,'DisplayName','Sat vapor' );
                plotter.legend('show', 'Location', 'best');
            end
            
            % Vapor ratios (void fraction and qualities)
            if any(ismember({'VR','ALL'},opt.display))
                plotter.newTile( ...
                    'tileTitle', 'Void fractions and qualities', ...
                    'xlabel'   ,                     'Time [s]', ...
                    'ylabel'   ,  'Quality / Void fraction [-]');
                %plotter.plotz(mix.transient('XEQ'    ,    'zIdx',zIdx)','Equil'       ,'DisplayName','Equilibrium quality');
                plotter.plotz(liq.transient('mix.XEQ',    'zIdx',zIdx)','Equil'       ,'DisplayName','Equilibrium quality');
                plotter.plotz(vap.transient('X'      ,    'zIdx',zIdx)','Vapor'       ,'DisplayName','Vapor mass quality' );
                plotter.plotz(vap.transient('VF'     ,liq,'zIdx',zIdx)','VoidFraction','DisplayName','Void fraction'      );
                plotter.legend('show', 'Location', 'best');
            end
            
            % Phase temperatures
            if any(ismember({'T','ALL'},opt.display))
                plotter.newTile( ...
                    'tileTitle',              'Phase temperatures', ...
                    'xlabel'   ,                        'Time [s]', ...
                    'ylabel'   , ['Temperature [' opt.unitTemp ']']);
                plotter.plotz(liq.transient('T','zIdx',zIdx)'+dTemp,'Liquid'    );
                plotter.plotz(vap.transient('T','zIdx',zIdx)'+dTemp,'Vapor'     );
                plotter.plotz(fld.transient('TSAT')'         +dTemp,'Saturation');
                plotter.legend('show', 'Location', 'best');
            end
            
            % Vapor and liquid mass exchanges
            if any(ismember({'PWE','ALL'},opt.display))
                ah_vap = plotter.newTile( ...
                    'tileTitle', 'Vapor mass exchanges', ...
                    'xlabel',                'Time [s]', ...
                    'ylabel',  'Mass exchange [kg/s/m]');
                plotter.plotz(vap.transient('MWALEVAP',liq,'zIdx',zIdx)','Evaporation'    ,'DisplayName','Wall evaporation'        );
                plotter.plotz(vap.transient('MINTEVAP',liq,'zIdx',zIdx)','InterfacialEvap','DisplayName','Interfacial evaporation' );
                plotter.plotz(vap.transient('MINTCOND',liq,'zIdx',zIdx)','InterfacialCond','DisplayName','Interfacial condensation');
                plotter.plotz(vap.transient('MTOT'    ,liq,'zIdx',zIdx)','Total'                                                   );
                plotter.legend('show', 'Location', 'best');
                ymax = max(arrayfun(@(x) max(abs(x.YLim)),plotter.gca))+1E-6;
                plotter.ylim([-ymax ymax]);
                
                ah_liq = plotter.newTile( ...
                    'tileTitle', 'Liquid mass exchanges', ...
                    'xlabel',                 'Time [s]', ...
                    'ylabel',   'Mass exchange [kg/s/m]');
                plotter.plotz(liq.transient('MWALEVAP',vap,'zIdx',zIdx)','Evaporation'    ,'DisplayName','Wall evaporation'        );
                plotter.plotz(liq.transient('MINTEVAP',vap,'zIdx',zIdx)','InterfacialEvap','DisplayName','Interfacial evaporation' );
                plotter.plotz(liq.transient('MINTCOND',vap,'zIdx',zIdx)','InterfacialCond','DisplayName','Interfacial condensation');
                plotter.plotz(liq.transient('MTOT'    ,vap,'zIdx',zIdx)','Total'                                                   );
                plotter.legend('show', 'Location', 'best');
                ymax = max(arrayfun(@(x) max(abs(x.YLim)),plotter.gca))+1E-6;
                plotter.ylim([-ymax ymax]);
                
                % Link exchange axes
                % TODO: this can be a plotter method
                for wallIdx = 1:length(ah_liq)
                    linkaxes([ah_vap(wallIdx), ah_liq(wallIdx)]);
                end
            end
            
            % Vapor and liquid momentum Exchanges
            if any(ismember({'PME','ALL'},opt.display))
                ah_vap = plotter.newTile( ...
                    'tileTitle', 'Vapor momentum exchanges', ...
                    'xlabel',                    'Time [s]', ...
                    'ylabel',          'Shear stress [N/m]');
                plotter.plotz(vap.transient('FWALL'   ,liq,'zIdx',zIdx)','Wall'           ,'DisplayName','Wall shear'             );
                plotter.plotz(vap.transient('FDRAG'   ,liq,'zIdx',zIdx)','Interfacial'    ,'DisplayName','Interfacial shear'      );
                plotter.plotz(vap.transient('FBUOY'   ,liq,'zIdx',zIdx)','Buoyancy'                                               );
                plotter.plotz(vap.transient('FGRAV'   ,liq,'zIdx',zIdx)','Gravity'                                                );
                plotter.plotz(vap.transient('FWALEVAP',liq,'zIdx',zIdx)','Evaporation'    ,'DisplayName','Wall evaporation'       );
                plotter.plotz(vap.transient('FINTEVAP',liq,'zIdx',zIdx)','InterfacialEvap','DisplayName','Interfacial evaporation');
                plotter.plotz(vap.transient('FTOT'    ,liq,'zIdx',zIdx)','Total'                                                  );
                plotter.legend('show', 'Location', 'best');
                ymax = max(arrayfun(@(x) max(abs(x.YLim)),plotter.gca))+1E-6;
                plotter.ylim([-ymax ymax]);
                
                ah_liq = plotter.newTile( ...
                    'tileTitle', 'Liquid momentum exchanges', ...
                    'xlabel',                     'Time [s]', ...
                    'ylabel',           'Shear stress [N/m]');
                plotter.plotz(liq.transient('FWALL'   ,vap,'zIdx',zIdx)','Wall'           ,'DisplayName','Wall shear'              );
                plotter.plotz(liq.transient('FDRAG'   ,vap,'zIdx',zIdx)','Interfacial'    ,'DisplayName','Interfacial shear'       );
                plotter.plotz(liq.transient('FBUOY'   ,vap,'zIdx',zIdx)','Buoyancy'                                                );
                plotter.plotz(liq.transient('FGRAV'   ,vap,'zIdx',zIdx)','Gravity'                                                 );
                plotter.plotz(liq.transient('FINTCOND',vap,'zIdx',zIdx)','InterfacialCond','DisplayName','Interfacial condensation');
                plotter.plotz(liq.transient('FTOT'    ,vap,'zIdx',zIdx)','Total'                                                   );
                plotter.legend('show', 'Location', 'best');
                ymax = max(arrayfun(@(x) max(abs(x.YLim)),plotter.gca))+1E-6;
                plotter.ylim([-ymax ymax]);
                
                % Link exchange axes
                % TODO: this can be a plotter method
                for wallIdx = 1:length(ah_liq)
                    linkaxes([ah_vap(wallIdx), ah_liq(wallIdx)]);
                end
            end
            
            % Vapor and liquid energy Exchanges
            if any(ismember({'PEE','ALL'},opt.display))
                ah_vap = plotter.newTile( ...
                    'tileTitle', 'Vapor energy exchanges', ...
                    'xlabel',                  'Time [s]', ...
                    'ylabel',     'Energy transfer [W/m]');
                plotter.plotz(vap.transient('HWALHEAT',    'zIdx',zIdx)','Wall'                                                    );
                plotter.plotz(vap.transient('HWALEVAP',liq,'zIdx',zIdx)','Evaporation'    ,'DisplayName','Wall evaporation'        );
                plotter.plotz(vap.transient('HINTEVAP',liq,'zIdx',zIdx)','InterfacialCond','DisplayName','Interfacial evaporation' );
                plotter.plotz(vap.transient('HINTCOND',liq,'zIdx',zIdx)','InterfacialEvap','DisplayName','Interfacial condensation');
                plotter.plotz(vap.transient('HTOT'    ,liq,'zIdx',zIdx)','Total'                                                   );
                plotter.legend('show', 'Location', 'best');
                ymax = max(arrayfun(@(x) max(abs(x.YLim)),plotter.gca))+1E-6;
                plotter.ylim([-ymax ymax]);
                
                ah_liq = plotter.newTile( ...
                    'tileTitle', 'Liquid energy exchanges', ...
                    'xlabel',                   'Time [s]', ...
                    'ylabel',      'Energy transfer [W/m]');
                plotter.plotz(liq.transient('HWALHEAT',    'zIdx',zIdx)','Wall'                                                    );
                plotter.plotz(liq.transient('HWALEVAP',vap,'zIdx',zIdx)','Evaporation'    ,'DisplayName','Wall evaporation'        );
                plotter.plotz(liq.transient('HINTEVAP',vap,'zIdx',zIdx)','InterfacialCond','DisplayName','Interfacial evaporation' );
                plotter.plotz(liq.transient('HINTCOND',vap,'zIdx',zIdx)','InterfacialEvap','DisplayName','Interfacial condensation');
                plotter.plotz(liq.transient('HTOT'    ,vap,'zIdx',zIdx)','Total'                                                   );
                plotter.legend('show', 'Location', 'best');
                ymax = max(arrayfun(@(x) max(abs(x.YLim)),plotter.gca))+1E-6;
                plotter.ylim([-ymax ymax]);
                
                % Link exchange axes
                % TODO: this can be a plotter method
                for wallIdx = 1:length(ah_liq)
                    linkaxes([ah_vap(wallIdx), ah_liq(wallIdx)]);
                end
            end
            
            % Volumetric interfacial area
            if any(ismember({'INTAREA','ALL'},opt.display))
                plotter.newTile( ...
                    'tileTitle', 'Volumetric interfacial area', ...
                    'xlabel'   ,                    'Time [s]', ...
                    'ylabel'   ,    'Interfacial area [m^-^1]');
                plotter.plotz(liq.transient('INTAREA',vap,'zIdx',zIdx)','Interfacial');
            end
            
            % Two-phase flow regimes
            if any(ismember({'REGIME','ALL'},opt.display))
                plotter.newTile( ...
                    'tileTitle', 'Two-phase flow regimes', ...
                    'xlabel'   ,     'Axial position [m]');
                plotter.plotz(liq.transient('FLOWID','zIdx',zIdx)','Interfacial')
                labels = arrayfun(@(x) unique(x.FLOWREGIME),liq,'uni',0);
                labels = strrep(cellstr(unique([labels{:}])),'_',' ');
                plotter.ylabels(labels);
                plotter.ylim([0 length(labels)+1]);
            end
            
        end
        
        function plotzt(twfSolver, opt)
        %PLOTZT: 2d plot, position z on horizontal and time t on vertical axis
        %
            
            arguments
                twfSolver
                opt.display      {mustBeA(opt.display,{'cell','char'})}                   = {         'HFLUX',                     'W',               'U',               'H',           'X',                 'VF'}
                opt.label        {mustBeA(opt.label,{'cell','char'})}                     = {'wall heat flux','mixture mass flow rate','mixture velocity','mixture enthalpy','mass quality','volumetric fraction'}
                opt.unit         {mustBeA(opt.unit,{'cell','char'})}                      = {         'W/m^2',                  'kg/s',             'm/s',            'J/kg',           '-',                  '-'}
                opt.field        {mustBeMember(opt.field,{'liquid','vapor'})}             = {'liquid','vapor'}
                opt.solveMode    {mustBeMember(opt.solveMode,{'TRANSIENT','STEADY'})}     = 'TRANSIENT'
                opt.wall         (1,:) double {mustBeVector,mustBeInteger,mustBePositive} = 1:twfSolver.inputSet.geometry.NWALL
                opt.zIdx         (:,1) double {mustBeVector,mustBeInteger,mustBePositive} = 1:twfSolver.NZ
                opt.tIdx         (:,1) double {mustBeVector,mustBeInteger,mustBePositive} = 1:twfSolver.NTIME
                opt.reverseTime  (1,1) logical                                            = false
                opt.shading      {mustBeMember(opt.shading,{'faceted','flat','interp'})}  = 'interp'
                opt.view         (1,2) double                                             = [0 90]
            end
            
            if ~iscell(opt.display), opt.display = {opt.display}; end
            if ~iscell(opt.label)  , opt.label   = {opt.label}  ; end
            if ~iscell(opt.unit)   , opt.unit    = {opt.unit}   ; end
            if strcmp('ALL',opt.display)
                    opt.display = {         'HFLUX',             'W',       'U',       'H',           'X',                 'VF',          'T',                    'INTAREA'};
                    opt.label   = {'wall heat flux','mass flow rate','velocity','enthalpy','mass quality','volumetric fraction','temperature','volumetric interfacial area'};
                    opt.unit    = {         'W/m^2',          'kg/s',     'm/s',    'J/kg',           '-',                  '-',          'K',                      'm^-^1'};
            end
            switch opt.solveMode
                case 'TRANSIENT'
                    liq = twfSolver.liquid(opt.tIdx);
                    vap = twfSolver.vapor(opt.tIdx);
                case 'STEADY'
                    if isequal(opt.tIdx,[1:twfSolver.NTIME]')
                        opt.tIdx = 1:length(twfSolver.liquidInit);
                    end
                    liq = twfSolver.liquidInit(opt.tIdx);
                    vap = twfSolver.vaporInit(opt.tIdx);
            end
            if isempty(opt.wall)
                opt.wall = 1:twfSolver.inputSet.geometry.NWALL;
            end
            if length(opt.zIdx) < 2
                twfSolver.log('Error: At least 2 axial indexes required to plot axial distributions.\n');
                return
            end
            if length(opt.tIdx) < 2
                twfSolver.log('Error: At least 2 time indexes required to plot time series.\n');
                return
            end
            
            for k = opt.wall
                if ismember('liquid',opt.field)
                    fh_liq = figure('name',['Time/axial distributions of two-fluid (liquid) parameters - ' opt.solveMode ' - Wall ' num2str(k)]);
                    for i = 1:length(opt.display)
                        ax_liq(i) = liq.plotzt(opt.display{i},['Liquid ' opt.label{i}],opt.unit{i},k,opt,vap);
                    end
                end
                if ismember('vapor',opt.field)
                    fh_vap = figure('name',['Time/axial distributions of two-fluid (vapor) parameters - ' opt.solveMode ' - Wall ' num2str(k)]);
                    for i = 1:length(opt.display)
                        ax_vap(i) = vap.plotzt(opt.display{i},['Vapor '  opt.label{i}],opt.unit{i},k,opt,liq);
                    end
                end
            end

        end
        
        function saveResults(twfSolver, opts)
        %SAVERESULTS
        %
        arguments
            twfSolver
            opts.saveFormat {mustBeMember(opts.saveFormat,["MAT"])}   = "MAT"
        end
            session = twfSolver.inputSet.session;
            switch opts.saveFormat
                case "MAT"
                    results = struct( ...
                                'Z', twfSolver.Z, ...
                                'TIME', twfSolver.TIME, ...
                                'sessionName', session.name, ...
                                'boundaryConditions', twfSolver.boundaryConditions, ...
                                'liquidInit', struct(twfSolver.liquidInit), ...
                                'vaporInit', struct(twfSolver.vaporInit), ...
                                'liquid', struct(twfSolver.liquid), ...
                                'vapor', struct(twfSolver.vapor));

                    if isfolder(session.directory)
                        save( ...
                            fullfile( ...
                                session.directory, strcat(session.name,'.mat')), ...
                            '-struct', ...
                            "results", ...
                            "-mat" ...
                        );
                    else
                        error('%s does not exist. Check Session.log.LOGMODE. Try session.makeSessionDirectory()');
                    end
            end


        end

    end
end

