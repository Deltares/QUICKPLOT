function average_trim(source,target,varargin)
%AVERAGE_TRIM Average fields of a TRIM file.
%    AVERAGE_TRIM(TRIM_Source,TRIM_Target)
%    Averages the time dependent data in a TRIM file TRIM_Source and stores
%    the results in a TRIM file called TRIM_Target. The file names may
%    include absolute or relative paths. If the target files exist, they
%    will be overwritten.
%
%    Examples:
%    average_trim('trim-source','trim-target')
%    average_trim('d:\sourcedir\trim-x','p:\targetdir\trim-x')
%
%    AVERAGE_TRIM(TRIM_Source,TRIM_Target,TimeSteps)
%    Takes the average value of only the selected time steps; TimeSteps should
%    be a row vector. By default all time steps are included in the averaging
%    process.
%
%    AVERAGE_TRIM(TRIM_Source,TRIM_Target,Operation)
%    Uses the specified Operation instead of the default operation 'mean'.
%    Alternative operations are:
%           'std'   : Standard deviation
%           'min'   : Minimum value
%           'max'   : Maximum value
%           'median': Median value
%
%    AVERAGE_TRIM(TRIM_Source,TRIM_Target,TimeSteps,Operation)
%    Uses only the selected time steps and applies the selected operation.
%
%    Notes:
%     * integer data sets (such as thindams) are not averaged. For those
%       data sets, the first field is copied into the new file.
%     * the operation is performed on the individual components of vector
%       quantities. So, for velocities you will obtain e.g. std(u) and std(v).

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
%   http://www.deltaressystems.com
%   $HeadURL$
%   $Id$

if nargin<1
   [source,p] = uigetfile({'trim-*.dat','Delft3D-FLOW map file'},'Select existing Delft3D-FLOW map file');
   source = [p source];
end
S=vs_use(source);

if nargin<2
   [target,p] = uiputfile([p 'trim-*.dat'],'Specify name for processed Delft3D-FLOW map file');
   target = [p target];
   [p,target] = fileparts(target); % strip off file extension
   target = [p target];
end
targetdat = [target '.dat'];
targetdef = [target '.def'];
if exist(targetdat,'file') | exist(targetdef,'file')
   errordlg({'The .DAT and .DEF files for processed data should not yet exist.',targetdat,targetdef},'Fatal Error','modal')
   return
end
T=vs_ini(targetdat,targetdef);

average='mean';
times = 0;
for i = 1:length(varargin)
   if ischar(varargin{i})
      average = varargin{i};
   elseif isnumeric(varargin{i})
      times = varargin{i};
   end
end

grps={'map-series','map-info-series','map-sed-series','map-infsed-serie','map-rol-series','map-infrol-serie','map-avg-series','map-infavg-serie','map-mor-series','WIND'};
for g=length(grps):-1:1
   Info=vs_disp(S,grps{g},[]);
   if ~isstruct(Info)
      grps(g)=[];
   end
end
%
% copy all fields of non time-dependent groups
%
notgrps=grps;
notgrps(2,:)={[]};
T=vs_copy(S,T,notgrps{:},'quiet');
%
% time-dependent groups: copy only first field
% to be overwritten by average
%
cpgrps=grps;
cpgrps(2,:)={{1}};
T=vs_copy(S,T,'*',[],cpgrps{:},'quiet');
%
% compute averages
%
for g=1:length(grps)
   elms=vs_disp(S,grps{g});
   for e=1:length(elms)
      Info=vs_disp(S,grps{g},elms{e});
      %
      % Only floating point data sets can be averaged
      %
      if Info.TypeVal==5
         Data = vs_let(S,grps{g},{times},elms{e});
         Data = feval(average,Data); % average in first (=time) direction
         T = vs_put(T,grps{g},elms{e},Data);
      end
   end
end
