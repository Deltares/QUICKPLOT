function [revString,repoUrl,hash] = determine_revision(dirname,dbid)
%DETERMINE_REVISION Determine the Git hash string.
%   STR = DETERMINE_REVISION(DIR) determines a revision string representing
%   the code status in the provided DIR using information from Git. For Git the
%   string consists of the short commit hash and a flag indicating whether the
%   code has changes compared to that commit.

%----- LGPL --------------------------------------------------------------------
%
%   Copyright (C) 2011-2026 Stichting Deltares.
%
%   This library is free software; you can redistribute it and/or
%   modify it under the terms of the GNU Lesser General Public
%   License as published by the Free Software Foundation version 2.1.
%
%   This library is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
%   Lesser General Public License for more details.
%
%   You should have received a copy of the GNU Lesser General Public
%   License along with this library; if not, see <http://www.gnu.org/licenses/>.
%
%   contact: delft3d.support@deltares.nl
%   Stichting Deltares
%   P.O. Box 177
%   2600 MH Delft, The Netherlands
%
%   All indications and logos of, and references to, "Delft3D" and "Deltares"
%   are registered trademarks of Stichting Deltares, and remain the property of
%   Stichting Deltares. All rights reserved.
%
%-------------------------------------------------------------------------------
%   http://www.deltaressystems.com
%   $HeadURL$
%   $Id$

% get hash
cwd = pwd;
cd(dirname)
[a,b] = system_plain('git -P log -n 1 -v --decorate');
% if we could remove -n 1, we could look for the latest hash available
% at the origin, but that triggers a pager to wait for keypresses. The
% option --no-pager before log seems to work on the command line, but
% not when called via system for some reason. This call returns
% something like:
%commit <hash> (HEAD -> <local_branch>, <origin_branch>)
%Author: ... author ...
%Date:   ... date and time ...
%
%    ... message ...
%
% Unfortunately, the branch names don't seem to appear on TeamCity ...
if a ~= 0
    revString = 'unknown';
    repoUrl   = 'unknown';
    hash      = 'unknown';
else
    [commit, b] = strtok(b); % takes the "commit" string
    [hash, b] = strtok(b); % takes the <hash>
    b = strsplit(b, local_newline); % splits to a cell string of which the first entry is the (HEAD ...) part
    
    teamcity_build_branch = getenv('TEAMCITY_BUILD_BRANCH');
    if ~isempty(teamcity_build_branch)
        % running on TeamCity ... don't look for origin ...
        hasLocalCommits = false;
    else
        hasLocalCommits = isempty(strfind(b{1}, 'origin/'));
    end

    % get repository
    [a, b] = system_plain('git remote -v');
    [origin, b] = strtok(b);
    [repoUrl, b] = strtok(b);

    % git describe
    %[a,b] = system_plain(['git describe "' dirname '"']);
    % returns something like: DIMRset_2.23.05-4-ge3176daa1
    % but I don't want QUICKPLOT to refer to "DIMRset" tags
    % however, neither should DIMRsets refer to QUICKPLOT tags.

    % get status
    [a, b] = system_plain(['git status "' dirname '"']);
    b = strsplit(b, local_newline);

    hasStagedChanges = check_and_list_files(b, 'Changes to be committed:', 'Staged files:\n', false);

    hasUnstagedChanges = check_and_list_files(b, 'Changes not staged for commit:', 'Modified files:\n', false);

    hasUntrackedChanges = check_and_list_files(b, 'Untracked files:', 'Untracked files:\n', true);

    % we should also check if we have local commits to be pushed.
    revString = hash(1:9);
    if hasLocalCommits || hasStagedChanges || hasUnstagedChanges || hasUntrackedChanges
        revString = [revString ' (changed)'];
    end
end
cd(cwd)

function checkResult = check_and_list_files(b, checkString, printString, mexExcept)
checkResult = false;
TAB = sprintf('\t');
isCheckString = strncmp(b, checkString, length(checkString));
if any(isCheckString)
    i = find(isCheckString) + 1;
    % skip lines starting with '(use' such as
    % (use "git add <file>..." to update what will be committed)
    i = i + 1;
    while i < length(b) && strcmp(strtok(b{i}), '(use')
        i = i + 1;
    end
    while i < length(b) && strcmp(b{i}(1), TAB)
        file = b{i}(2:end);
        % skip 'modified:' substring if found ...
        if strncmp(file, 'modified:', 9)
            file = strtrim(file(10:end));
        end
        folderAndFile = strsplit(file, '/');
        if length(folderAndFile) == 1 || strcmp(folderAndFile{1}, 'private')
            % file in current folder
            % or file in private folder or below
            if mexExcept && ~isempty(strfind(folderAndFile{end}, '.mex'))
                % we need to ignore added mex files for the build process
            else
                if ~checkResult
                    fprintf(printString);
                    checkResult = true;
                end
                fprintf(' * %s\n', file);
            end
        end
        i = i + 1;
    end
    if checkResult
        fprintf('\n');
    end
end

function s = local_newline
if matlabversionnumber > 9.01
    s = newline;
else
    s = char(10);
end


function [err,output] = system_plain(cmd)
[err,output] = system(cmd);
output = strip_ansi(output);


function s = strip_ansi(s)
% https://en.wikipedia.org/wiki/ANSI_escape_code

% CSI sequences
parameter_bytes = '[0-9:;<=>?]*';
intermediate_bytes = '[!"#$%&''()*+,-./]*';
final_byte = '[@A-Z\[\\\]\^_`a-z{|}~]';
s = regexprep(s, [char(27),'\[',parameter_bytes,intermediate_bytes,final_byte],'');

% Escape sequences
s = regexprep(s, [char(27) '.'],'');
