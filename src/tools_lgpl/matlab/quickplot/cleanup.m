function cleanup(X)
%CLEANUP  removes files and directories
%   CLEANUP(X)
%   X is a cell array of files and/or directories
%   for instance:
%   X={'*.bak' 'subdir'}

%   $Id$

if isunix
    for i=1:length(X(:))
        unix(['rm -rf ' X{i}]);
    end
else
    for i=1:length(X(:))
        X{i}=strrep(X{i},'/','\');
        if isdir(X{i})
            [s,msg]=dos(['rmdir /s/q ' X{i}]);
        else
            [s,msg]=dos(['del /f/q ' X{i}]);
        end
        if s~=0
            if isdir(X{i})
                [s,msg]=dos(['rmdir /s/q ' X{i}]);
            end
            if s~=0
                error(msg);
            end
        end
    end
end
