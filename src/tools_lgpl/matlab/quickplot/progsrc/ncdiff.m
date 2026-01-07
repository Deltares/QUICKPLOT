function argout = ncdiff(file1, file2)
%NCDIFF - Compares the content of two NetCDF files.
%   This function compares the content of two NetCDF files and reports the
%   differences. It compares (global) attributes and variables. It does not
%   differences in unused dimensions.
%
%   Syntax
%     NCDIFF(fileName1, fileName2)
%
%   Input Arguments
%     fileName1 - Name of the first NetCDF file
%     fileName2 - Name of the second NetCDF file
%
%   See also NETCDF, NCCOPY

%----- LGPL --------------------------------------------------------------------
%                                                                               
%   Copyright (C) 2011-2025 Stichting Deltares.                                     
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

ncInfo1 = ncinfo(file1);
ncInfo2 = ncinfo(file2);
fprintf('File 1: %s\n', ncInfo1.Filename);
fprintf('File 2: %s\n\n', ncInfo2.Filename);
anydiff = check_fields(ncInfo1, ncInfo2, dimension_diff_reporter('global'));
anydiff = anydiff | check_fields(ncInfo1, ncInfo2, variable_diff_reporter(file1, file2));
anydiff = anydiff | check_fields(ncInfo1, ncInfo2, attribute_diff_reporter('global'));
if nargout == 1
    argout = anydiff;
end

% routine to check and report any differences for a series of variables or
% attributes.
function anydiff = check_fields(ncInfo1, ncInfo2, reporter)
if reporter.verbose
    fprintf('Comparing %ss ...\n', reporter.fld_longname);
end
structList1 = ncInfo1.(reporter.fld);
structList2 = ncInfo2.(reporter.fld);
if isempty(structList1)
    nameList1 = {};
else
    nameList1 = {structList1.Name};
end
if isempty(structList2)
    nameList2 = {};
else
    nameList2 = {structList2.Name};
end

anydiff = false;
namesOnlyIn1 = setdiff(nameList1, nameList2);
if ~isempty(namesOnlyIn1)
    anydiff = true;
    fprintf_setdiff(reporter,1,namesOnlyIn1)
end
namesOnlyIn2 = setdiff(nameList2, nameList1);
if ~isempty(namesOnlyIn2)
    anydiff = true;
    fprintf_setdiff(reporter,2,namesOnlyIn2)
end
nameList = intersect(nameList1, nameList2);

for i = 1:length(nameList)
    name = nameList{i};
    i1 = strcmp(nameList1, name);
    i2 = strcmp(nameList2, name);

    info1 = ncInfo1.(reporter.fld)(i1);
    info2 = ncInfo2.(reporter.fld)(i2);

    anydiff = anydiff | reporter.report(info1, info2);
end

if reporter.verbose
    if ~anydiff
        fprintf('No differences found.\n');
    end
    fprintf('\n');
end

% report differences in two sets
function fprintf_setdiff(reporter,fileN,namesOnlyInN)
fprintf('%s%ss only found in file %i:\n', reporter.indent, reporter.fld_longname, fileN);
for i = 1:length(namesOnlyInN)
    fprintf('%s   %s\n',reporter.indent,namesOnlyInN{i});
end

% reporter for variable differences
function reporter = variable_diff_reporter(file1,file2)
reporter.fld = 'Variables';
reporter.fld_longname = 'variable';
reporter.indent = '';
reporter.verbose = true;
reporter.report = @(x,y) report_variable_differences(x,y,file1,file2);

% actual variable difference reporter
function anydiff = report_variable_differences(info1, info2, file1, file2)
anydiff = false;
name = info1.Name;
flds = fieldnames(info1);
for i = 1:length(flds)
    fld1 = info1.(flds{i});
    fld2 = info2.(flds{i});
    if ~isequal(fld1,fld2)
        if ~anydiff
            anydiff = 1;
            fprintf('=> variable %s:\n', name);
        end
        switch flds{i}
            case 'Attributes'
                anydiff = check_fields(info1, info2, attribute_diff_reporter('local'));
            case 'Dimensions'
                anydiff = check_fields(info1, info2, dimension_diff_reporter('local'));
            otherwise
                vardiff(fld1,fld2)
        end
    end
end

if isequal(info1.Size,info2.Size)
    varData1 = ncread(file1, name);
    varData2 = ncread(file2, name);
    common_fillvalue = 0;
    if isstruct(info1.Attributes)
        ifill = info1.Attributes(strcmp({info1.Attributes.Name},'_FillValue'));
        if ~isempty(ifill)
            varData1(isnan(varData1)) = common_fillvalue;
        end
    end
    if isstruct(info2.Attributes)
        ifill = info2.Attributes(strcmp({info2.Attributes.Name},'_FillValue'));
        if ~isempty(ifill)
            varData2(isnan(varData2)) = common_fillvalue;
        end
    end
    switch vardiff(varData1, varData2)
        case 0
            % equal
        otherwise
            if ~anydiff
                anydiff = true;
                fprintf('=> variable %s:\n', name);
            end
            vardiff(varData1, varData2)
    end
end

% reporter for dimension differences
function reporter = dimension_diff_reporter(scope)
reporter.fld = 'Dimensions';
reporter.fld_longname = 'dimension';
switch scope
    case 'global'
        reporter.indent = '';
        reporter.verbose = true;
        reporter.report = @(x,y) report_dimension_differences(x,y,'=>','  ');
    otherwise
        reporter.indent = '   ';
        reporter.verbose = false;
        reporter.report = @(x,y) report_dimension_differences(x,y,'  ','     ');
end

% actual attrbute difference reporter
function anydiff = report_dimension_differences(info1, info2, prefix1, prefix2)
anydiff = false;
name = info1.Name;
if ~isequal(info1.Length, info2.Length) || ~isequal(info1.Unlimited, info2.Unlimited)
    anydiff = true;
    fprintf('%s dimension %s:\n', prefix1, name);
    fprintf('%s length 1: %i (unlimited = %i)\n', prefix2, info1.Length, info1.Unlimited)
    fprintf('%s length 2: %i (unlimited = %i)\n', prefix2, info2.Length, info2.Unlimited)
end

% reporter for attribute differences
function reporter = attribute_diff_reporter(scope)
reporter.fld = 'Attributes';
switch scope
    case 'global'
        reporter.fld_longname = 'global attribute';
        reporter.indent = '';
        reporter.verbose = true;
        reporter.report = @(x,y) report_attribute_differences(x,y,'=>','  ');
    otherwise
        reporter.fld_longname = 'attribute';
        reporter.indent = '   ';
        reporter.verbose = false;
        reporter.report = @(x,y) report_attribute_differences(x,y,'  ','     ');
end

% actual attrbute difference reporter
function anydiff = report_attribute_differences(info1, info2, prefix1, prefix2)
anydiff = false;
name = info1.Name;
if ~isequal(info1.Value, info2.Value)
    anydiff = true;
    fprintf('%s attribute %s:\n', prefix1, name);
    fprintf('%s value 1: %s\n', prefix2, var2str(info1.Value))
    fprintf('%s value 2: %s\n', prefix2, var2str(info2.Value))
end
