function [G,GridFileName]=get_matching_grid(MapSeg,pn,filterspec)
%GET_MATCHING_GRID Get grid file that matches size of current dataset.
%   [GRIDINFO,GRIDFILENAME] = GET_MATCHING_GRID(MAPSEG) opens a dialog to
%   select a file with MAPSEG elements in the (aggregated) grid.
%
%   [GRIDINFO,GRIDFILENAME] = GET_MATCHING_GRID(GRIDSIZE) opens a dialog to
%   select a grid specified GRIDSIZE.

%----- LGPL --------------------------------------------------------------------
%                                                                               
%   Copyright (C)  Stichting Deltares, 2011.                                     
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
%   http://www.delftsoftware.com
%   $HeadURL$
%   $Id$

GridSeg=-1;
PerLayer=0;
CouldReadGridData = 0;
filters = {'*.cco;*.lga' 'Delft3D Grid (Aggregation) Files'
    '*.m2b' 'SOBEK Grid Aggregation Files'
    '*.geo;geo*' 'Telemac Grid Files'};
if nargin<3
   filterspec = '';
end
while 1
   if exist(filterspec)==2
      GridFileName=filterspec;
   else
      cp=pwd;
      cd(pn);
      [gfn,gpn]=uigetfile(filters,'Select matching grid file ...');
      cd(cp);
      if ~ischar(gfn)
         G=[];
         GridFileName='';
         break
      end
      GridFileName=[gpn gfn];
   end
   ex='';
   [pn,fn,ex]=fileparts(GridFileName);
   trytp = lower(ex);
   trytp0 = trytp;
   CouldReadGridData = 0;
   while 1
      GridSize=[NaN NaN];
      GridSeg=NaN;
      switch trytp
         case {'.lga','.cco'}
            try
               G=delwaq('open',GridFileName);
               GridSeg=G.NoSeg;
               PerLayer=G.NoSegPerLayer;
               CouldReadGridData = 1;
            catch
               trytp = '.grd';
            end
         case {'.grd'}
            try
               G=wlgrid('open',GridFileName);
               GridSize=size(G.X);
               CouldReadGridData = 1;
            catch
               trytp = '.m2b';
            end
         case {'.m2b','.arc'}
            try
               G=arcgrid('read',GridFileName);
               GridSeg=max(G.Data(:));
               PerLayer=GridSeg;
               G.MNK=[size(G.Data) 1];
               G.Index=G.Data;
               G.Index(isnan(G.Data))=0;
               CouldReadGridData = 1;
            catch
               trytp = '.geo';
            end
         case {'.geo'}
            try
               G=telemac('open',GridFileName);
               GridSeg=G.Discr.NPnts;
               PerLayer=GridSeg;
               G.MNK=[G.Discr.NPnts 1];
               G.Index=(1:GridSeg)';
               CouldReadGridData = 1;
            catch
               trytp = 'unknown';
            end
         otherwise
            trytp0 = 'unknown';
            trytp = '.lga';
      end
      if CouldReadGridData | isequal(trytp,trytp0)
         break
      end
   end
   if CouldReadGridData
      if length(MapSeg)==1
         %
         % Number of segments given.
         %
         if MapSeg==GridSeg | ... % exact match for ordinary map files
               MapSeg==GridSeg+PerLayer % one shift for PART map files with sediment layer
            break
         elseif round(MapSeg/GridSeg)==MapSeg/GridSeg & GridSeg>0 % data amount matches multiple layers
            G.MNK(3) = MapSeg/GridSeg;
            G.Index = repmat(G.Index,[1 1 G.MNK(3)]);
            for k=2:G.MNK(3)
               G.Index(:,:,k)=G.Index(:,:,k)+(k-1)*GridSeg;
            end
            break
         else
            ui_message('error',sprintf('Number of segments in map file (%i) does not\nmatch the number of segments in the\ngrid file (%i)',MapSeg,GridSeg));
         end
      else
         %
         % Grid dimensions given.
         %
         if isequal(GridSize,MapSeg)
            break
         else
            ui_message('error',sprintf('Grid size (%ix%i) does not match data size (%ix%i)',GridSize,MapSeg));
         end
      end
   end
end
