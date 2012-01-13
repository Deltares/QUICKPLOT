function filtertbl = qp_filefilters(cmd)
%QP_FILEFILTERS Obtain a list of file filters.
%   FILTERS = QP_FILEFILTERS('all') returns all file filters.

%----- LGPL --------------------------------------------------------------------
%                                                                               
%   Copyright (C) 2011-2012 Stichting Deltares.                                     
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

filtertbl={...
    '*.dat;*.ada;*.hda'                                    'Delft3D Output Files'              'nefis'
    '*.grd;*.rgf'                                          'Delft3D Grid Files'                'wlgrid'
    '*.mesh'                                               'Mike Flexible Mesh Files'          'mikemesh'
    '*.14'                                                 'Adcirc Mesh Files'                 'adcircmesh'
    '*.mesh;*.node;*.ele;*.n;*.e'                          'EasyMesh and Triangle Mesh Files'  'nodelemesh'
    '*.bct;*.bcc;*.bcb'                                    'Delft3D-FLOW Bound. Cond. Files'   'bct'
    '*.am?;*.spw;*.wnd'                                    'Delft3D/SOBEK Meteo Files'         'asciiwind'
    'gcmplt.*;gcmtsr.*'                                    'ECOMSED Binary Files'              'ecomsed-binary'
    '*.stu;*.pst'                                          'JSPost Files'                      'JSPost'
    '*.xyz'                                                'Sample Files'                      'samples'
    '*.nc'                                                 'NetCDF Files'                      'NetCDF'
    '*.grib;*.grib1;*.grib2'                               'GRIB Files'                        'grib'
    'sds-*'                                                'Simona SDS Files'                  'waquasds'
    '*.his;*.map;*.plo;*.psf;*.lga'                        'Delwaq Binary Files'               'delwaqbin'
    '*.tim'                                                'Delwaq Time Series Input Files'    'DelwaqTimFile'
    '*.arc;*.am?;*.asc'                                    'ARC/INFO Ascii Grid Files'         'arcgrid'
    '*.map'                                                'PC-Raster Files'                   'pcraster'
    '*.hdr'                                                'BIL/HDR Files'                     'bil/hdr'
    '*.tek;*.ann;*.ldb;*.pol;*.spl;*.tka;*.tkp;*.tkf'      'Tekal Data Files'                  'tekal'
    '*.shp'                                                'Shape Files'                       'shape'
    '*.gen'                                                'ArcInfo Ungenerate Files'          'ArcInfoUngenerate'
    '*.bna'                                                'BNA Files'                         'BNA File'
    '*.jpg;*.jpeg;*.bmp;*.tif;*.tiff;*.png;*.pcx;*.xwd'    'Bitmap Files'                      'bitmap'
    '*.fun;*.daf'                                          'Unibest Files'                     'unibest'
    '*.sp1;*.sp2;*.s1d;*.s2d'                              'SWAN Spectral Files'               'SWAN spectral'
    '*.slf;*.out;*.res'                                    'Telemac Files'                     'telemac'
    '*.dt0;*.dt1;*.dt2;*.dfs0;*.dfs1;*.dfs2;*.dfs3;*.dfsu' 'Mike Data Files'                   'mike0'
    'DEFTOP.1;NETWORK.NTW'                                 'Sobek Networks'                    'sobek1d'
    '*.inc;*.crs;*.bin'                                    'FLS Files'                         'fls'
    '*.seq'                                                'AukePC Files'                      'aukepc'
    '*.mat'                                                'MATLAB Files (Exported from QP)'   'matlab'
    '*.dmp'                                                'CFX4 Dump Files'                   'CFX dmp'
    };

if nargin<1
    cmd = '';
end
switch cmd
    case 'all'
    case 'selected'
       filterstring = qp_settings('filefilterselection');
       iquotes = findstr('"',filterstring);
       selected = cell(1,length(iquotes)/2);
       for i = 1:length(iquotes)/2
          selected{i} = filterstring(iquotes((i-1)*2+1)+1:iquotes(i*2)-1);
       end
       [selected,iFull] = intersect(filtertbl(:,2),selected);
       filtertbl = filtertbl(iFull,:);
    otherwise % Delft3D output and last file type
        lasttp  = qp_settings('LastFileType','nefis');
        ilasttp = strncmp(lasttp,filtertbl(:,3),length(lasttp));
        ilasttp(1) = 1;
        filtertbl = filtertbl(ilasttp,:);
end
[dum,Reorder] = sort(filtertbl(:,2));
filtertbl = filtertbl(Reorder,:);
