classdef REGIMES < double
    %REGIMES Enum class of the 6 regimes considered
    %
    %   The 6 regimes are defined as a enum class to increase computational
    %   efficiency while increasing readability of code, particularly when
    %   different calculations are carried out for different flow regimes.
    %   
    %   ...
    
    enumeration
        LIQUID              (0)
        BUBBLY_SUBCOOLED    (1)
        BUBBLY_SATURATED    (2)
        INTERMEDIATE        (3)
        ANNULAR             (4)
        DFFB                (5)
        
    end
end

