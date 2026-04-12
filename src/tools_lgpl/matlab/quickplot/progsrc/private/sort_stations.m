function [out1,out2] = sort_stations(in1,stationSortMethod)
%sort_stations Routine to sort station names

NONE = 'No Sorting';
ALPHABETICAL = 'Sorted Alphabetically';

if nargin == 1 && nargout <= 1
    switch in1
        case 'methods'
            out1 = {NONE,ALPHABETICAL};
        case 'default'
            out1 = NONE;
        otherwise
            error('Unexpected command: %s.', in1)
    end

else
    switch stationSortMethod
        case NONE
            out1 = in1;
            out2 = 1:length(in1);

        case ALPHABETICAL
            [out1,out2] = sort(in1);

        otherwise
            error('Sort method %s not implemented.', stationSortMethod)
    end
end