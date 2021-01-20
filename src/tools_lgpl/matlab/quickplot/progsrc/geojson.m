function varargout = geojson(cmd, varargin)
%GEOJSON Read/write GeoJSON files.

%----- LGPL --------------------------------------------------------------------
%                                                                               
%   Copyright (C) 2011-2021 Stichting Deltares.                                     
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

lcmd = lower(cmd);
switch lcmd
    case 'open'
        [varargout{1:max(nargout,1)}] = openfile(varargin{:});
    case 'write'
        if nargout == 0
            writefile(varargin{:});
        else
            [varargout{1:nargout}] = writefile(varargin{:});
        end
end

function DUMMY = writefile(filename, geomtype, id, geometry, properties)
DUMMY = [];

lbreak = '\n';
indent = '    ';
geofloat = '%.15g';
propfloat = '%.15g';

propnames = {};
if nargin < 5
    properties = [];
elseif ~isempty(properties)
    propnames = fieldnames(properties);
end
nprops = numel(propnames);
hasprops = nprops > 0;

indent2 = [indent, indent];
indent3 = [indent2, indent];
indent4 = [indent2, indent2];
indent5 = [indent3, indent2];

fid = fopen(filename, 'w');
fprintf(fid, ['{' lbreak indent '"type": "FeatureCollection",' lbreak indent '"features": [{' lbreak]);
for i = 1:length(geometry)
    if i > 1
        fprintf(fid, [indent '}, {' lbreak]);
    end
    fprintf(fid, [indent2 '"type": "Feature",' lbreak indent2 '"id": "%s"' lbreak indent2 '"geometry": {' lbreak], id{i});
    switch geomtype
        case 'point'
            fprintf(fid, [indent3 '"type": "Point",' lbreak indent3 '"coordinates": [' geofloat ', ' geofloat ']' lbreak], geometry{i});
        case 'polyline'
            fprintf(fid, [indent3 '"type": "LineString",' lbreak indent3 '"coordinates": [' lbreak]);
            fprintf(fid, [indent4 '[' geofloat ', ' geofloat '],' lbreak], geometry{i}(1:end-1,:)');
            fprintf(fid, [indent4 '[' geofloat ', ' geofloat ']' lbreak], geometry{i}(end,:));
            fprintf(fid, [indent3 ']' lbreak]);
        case 'polygon'
            fprintf(fid, [indent3 '"type": "Polygon",' lbreak indent3 '"coordinates": [' lbreak indent4 '[' lbreak]);
            fprintf(fid, [indent5 '[' geofloat ', ' geofloat '],' lbreak], geometry{i}(1:end-1,:)');
            fprintf(fid, [indent5 '[' geofloat ', ' geofloat ']' lbreak], geometry{i}(end,:));
            fprintf(fid, [indent4 ']' lbreak indent3 ']' lbreak]);
    end
    fprintf(fid, [indent2 '},' lbreak indent2 '"properties": ']);
    if hasprops
        fprintf(fid, ['{' lbreak]);
        end_prev_prop = '';
        for p = 1:nprops
            propValues = properties.(propnames{p});
            if iscell(propValues)
                val = propValues{i};
            else
                val = propValues(i);
            end
            if isempty(val)
                continue
            elseif ischar(val)
                propval = sprintf('"%s"', val);
            elseif isnan(val)
                propval = 'null';
            else
                propval = sprintf(propfloat, val);
            end
            fprintf(fid, [end_prev_prop indent3 '"%s": %s'], propnames{p}, propval);
            end_prev_prop = [',' lbreak];
        end
        fprintf(fid, [lbreak indent2 '}' lbreak]);
    else
        fprintf(fid, ['null' lbreak]);
    end
end
fprintf(fid, [indent '}]' lbreak '}' lbreak]);
fclose(fid);