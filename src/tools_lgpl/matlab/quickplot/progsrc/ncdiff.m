function ncdiff(file1, file2)
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
check_fields(ncInfo1, ncInfo2, 'global attribute', 'Attributes', @(x,y) report_attribute_differences(x,y));
check_fields(ncInfo1, ncInfo2, 'variable', 'Variables', @(x,y) report_variable_differences(x,y,file1,file2));


function check_fields(ncInfo1, ncInfo2, typeName, fld, diff_reporter)
fprintf('Comparing %ss ...\n', typeName);
structList1 = ncInfo1.(fld);
structList2 = ncInfo2.(fld);
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
    fprintf('%ss only found in file 1:\n', typeName);
    fprintf('   %s\n',namesOnlyIn1{:});
    fprintf('\n');
end
namesOnlyIn2 = setdiff(nameList2, nameList1);
if ~isempty(namesOnlyIn2)
    anydiff = true;
    fprintf('%ss only found in file 2:\n', typeName);
    fprintf('   %s\n',namesOnlyIn2{:});
    fprintf('\n');
end
nameList = intersect(nameList1, nameList2);

for i = 1:length(nameList)
    name = nameList{i};
    i1 = strcmp(nameList1, name);
    i2 = strcmp(nameList2, name);

    info1 = ncInfo1.(fld)(i1);
    info2 = ncInfo2.(fld)(i2);

    anydiff = anydiff | diff_reporter(info1, info2);
end

if ~anydiff
    fprintf('No differences found.\n');
end
fprintf('\n');


function anydiff = report_variable_differences(info1, info2, file1, file2)
anydiff = false;
name = info1.Name;
switch vardiff(info1, info2)
    case 0
        varData1 = ncread(file1, name);
        varData2 = ncread(file2, name);
        ifill = info1.Attributes(strcmp({info1.Attributes.Name},'_FillValue'));
        if ~isempty(ifill)
            fill_value = ifill.Value;
            varData1(isnan(varData1)) = fill_value;
            varData2(isnan(varData2)) = fill_value;
        end
        switch vardiff(varData1, varData2)
            case 0
                % equal
            otherwise
                anydiff = true;
                fprintf('=> variable %s:\n', name);
                vardiff(varData1, varData2)
        end
    otherwise
        anydiff = true;
        fprintf('=> variable %s:\n', name);
        vardiff(info1, info2)
end


function anydiff = report_attribute_differences(info1, info2)
anydiff = false;
name = info1.Name;
if ~isequal(info1.Value, info2.Value)
    anydiff = true;
    fprintf('=> attribute %s:\n', name);
    fprintf('   value 1: %s\n', info1.Value)
    fprintf('   value 2: %s\n', info2.Value)
end
