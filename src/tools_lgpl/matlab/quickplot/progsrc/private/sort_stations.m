function [out1,out2] = sort_stations(in1,stationSortMethod)
%sort_stations Routine to sort station names

NONE = 'No Sorting';
LEXICOGRAPHICAL = 'Lexicographical Sorting';
LEXICOGRAPHICAL_CI = 'Case-insensitive Lexicographical Sorting';
ALPHANUMERICAL = 'Alpha-Numerical Sorting';
ALPHANUMERICAL_CI = 'Case-insensitive Alpha-Numerical Sorting';

if nargin == 1 && nargout <= 1
    switch in1
        case 'methods'
            out1 = {NONE,LEXICOGRAPHICAL,LEXICOGRAPHICAL_CI,ALPHANUMERICAL,ALPHANUMERICAL_CI};
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

        case LEXICOGRAPHICAL
            [out1,out2] = sort(in1);

        case LEXICOGRAPHICAL_CI
            [~,out2] = sort(lower(in1));
            out1 = str(out2);

        case ALPHANUMERICAL
            out2 = alphanumSort(in1);
            out1 = in1(out2);

        case ALPHANUMERICAL_CI
            out2 = alphanumSort(lower(in1));
            out1 = in1(out2);

        otherwise
            error('Sort method %s not implemented.', stationSortMethod)
    end
end

function idx = alphanumSort(str)
%ALPHANUMSORT Natural (alphanumeric) sort of strings
%
%   idx = alphanumSort(str)
%
%   Input:
%     str - cell string OR string array
%
%   Output:
%     idx - sorting order

% Accept cell string and string array
if ~isstring(str) && ~iscellstr(str)
    error('Input must be a cell a cell string or a string array.');
end

tokens = cellfun(@split, str, 'UniformOutput', false);
nTokens = cellfun(@numel,tokens);
maxTokens = max(nTokens);
key = repmat({'',0},numel(str), ceil(maxTokens/2));

for i = 1:numel(str)
    key(i,1:nTokens(i)) = tokens{i};
end

% Sort rows lexicographically
[~, idx] = sortrows(key);


function tokens = split(str)
isNumber = str>='0' & str<='9';
tokenStart = find(diff(isNumber)) + 1;
nTokens = numel(tokenStart)+1;
startsWithNumber = isNumber(1);

blankedStr = str;
blankedStr(~isNumber) = ' ';
values = num2cell(sscanf(blankedStr,'%u'));

tokens  = cell(1,nTokens+startsWithNumber);
for i = 1+startsWithNumber:2:nTokens
    if i == 1
        if nTokens == 1
            tokens{i} = str;
        else
            tokens{i} = str(1:tokenStart(i)-1);
        end
    elseif i == nTokens
        tokens{i} = str(tokenStart(i-1):end);
    else
        tokens{i} = str(tokenStart(i-1):tokenStart(i)-1);
    end
end
tokens(2-startsWithNumber:2:end) = values;
