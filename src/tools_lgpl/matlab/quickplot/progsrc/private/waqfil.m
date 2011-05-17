function S = waqfil(cmd,file,varargin)
%WAQFIL Read various Delwaq files.
%
%   FI = WAQFIL('open',FILENAME,...extra arguments...)
%   Opens the specified file and reads a part or all of the
%   data.
%
%   Data = WAQFIL('read',FI,...extra arguments...)
%   Reads additional data from the file.
%
%   This function call supports the following file types
%   (the extra arguments for the open call are indicated
%   after the list of file name extensions).
%
%   Volume, salinity, temperature, and shear stress files
%     * .vol, .sal, .tem, .vdf, .tau files: NSeg
%
%   Segment function files
%     * .segfun files                     : NSeg, NPar
%
%   Flow area and flux files
%     * .are, .flo files                  : NExch
%
%   Pointer table files
%     * .poi files                        : NExch
%
%   Distance table files
%     * .len files                        : NExch
%
%   Chezy files
%     * .chz files                        : -
%
%   Segment surface area and depth files
%     * .srf, *.dps files                 : -
%
%   table files
%     * .lgt files                        : -

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

switch lower(cmd)
    case 'open'
        [p,f,e]=fileparts(file);
        switch lower(e)
            case {'.vol','.sal','.tem','.vdf','.tau'}
                S = openvol(file,varargin{:});
            case {'.segfun'}
                S = opensegfun(file,varargin{:});
            case {'.are','.flo'}
                S = openare(file,varargin{:});
            case '.poi'
                S = openpoi(file,varargin{:});
            case '.len'
                S = openlen(file,varargin{:});
            case '.chz'
                S = openchz(file,varargin{:});
            case {'.srf','.dps'}
                S = opensrf(file,varargin{:});
            case '.lgt'
                S = openlgt(file,varargin{:});
            otherwise
                error('Unrecognized file type')
        end
        S.FileType = lower(e);
    case 'read'
        switch file.FileType
            case {'.vol','.sal','.tem','.vdf','.tau'}
                S = readvol(file,varargin{:});
            case {'.are','.flo'}
                S = readvol(file,varargin{:});
            case {'.segfun'}
                S = readvol(file,varargin{:});
            case '.poi'
                S = readpoi(file,varargin{:});
            case '.len'
                S = readlen(file,varargin{:});
            case '.chz'
                S = readchz(file,varargin{:});
            case {'.srf','.dps'}
                %S = readsrf(file,varargin{:});
                S = file.Srf;
            case '.lgt'
                S = readlgt(file,varargin{:});
        end
end

%% Ind file
function S = openinp(file)
S.NSegments = 2;
S.NExhanges = 1;

function nseg = detect_nseg(file)
if ischar(file)
    S = openinp(file);
else
    S = file;
end
nseg = S.NSegments;

function nexch = detect_nexch(file)
if ischar(file)
    S = openinp(file);
else
    S = file;
end
nexch = S.NExchanges;

%% Vol file
function S = openvol(file,nseg)
if nargin<2
    nseg = detect_nseg(file);
end
S = openfile(file,nseg);

function D = readvol(file,itime,ipar)
if nargin<3
    ipar = 1:file.NPar;
end
fid = fopen(file.FileName,'r');
fseek(fid,((itime-1)*(file.NVals*file.NPar+1)+1)*4,-1);
D = fread(fid,[file.NVals file.NPar],'float32');
D = D(:,ipar);
fclose(fid);

%% Segfun file
function S = opensegfun(file,nseg,npar)
if nargin<2
    nseg = detect_nseg(file);
end
S = openfile(file,nseg,npar);

%% Are or Flo file
function S = openare(file,nexch)
if nargin<2
    nexch = detect_nexch(file);
end
sum_noq = sum(nexch);
S = openfile(file,sum_noq);

%% Vol, Are or Flo File
function S = openfile(file,nval,npar)
if nargin<3
    npar = 1;
end
fid = fopen(file,'r');
S.FileName = file;
S.NVals = nval;
S.NPar = npar;
%
%time=fread(fid,1,'int32');
%vals=fread(fid,nval,'float32');
%
fseek(fid,0,1);
fz = ftell(fid);
nbytes_pertime = (nval*npar+1)*4;
S.NTimes = fz/nbytes_pertime;
%
fseek(fid,0,-1);
S.Times = fread(fid,S.NTimes,'int32',nbytes_pertime-4);
%
%fseek(fid,0,-1);
%S.Vals = zeros(nval,npar,S.NTimes);
%for t = 1:S.NTimes
%    fread(fid,1,'int32');
%    S.Vals(:,:,t) = fread(fid,[nval npar],'float32');
%end
%
fclose(fid);

%% Poi File
function S = openpoi(file)
fid = fopen(file,'r');
S.FileName = file;
%
S.Pointer=fread(fid,[4 inf],'int32')';
S.PointerLabels={'From','To','Upstream_of_From','Downstream_of_To'};
%
fclose(fid);

%% Len File
function S = openlen(file)
fid = fopen(file,'r');
S.FileName = file;
%
S.Sum_NOQ = fread(fid,1,'int32');
S.Dist    = fread(fid,[2 S.Sum_NOQ],'float32')';
S.DistLabels={'Distance_from_From_to_Interface','Distance_from_Interface_to_To'};
%
fclose(fid);

%% Chz File
function S = openchz(file)
fid = fopen(file,'r');
S.FileName = file;
%
S.NLayers = fread(fid,1,'int32');
S.Dims    = fread(fid,[1 2],'int32');
S.NAct    = fread(fid,1,'int32');
S.XXX     = fread(fid,[1 3],'int32');
S.Chezy   = fread(fid,[S.NAct 2],'float32')';
S.ChezyLabels = {'Chezy_Direction1','Chezy_Direction2'};
%
fclose(fid);

%% Srf File
function S = opensrf(file)
fid = fopen(file,'r');
S.FileName = file;
%
S.Dims    = fread(fid,[1 2],'int32');
S.NAct    = fread(fid,1,'int32');
S.XXX     = fread(fid,[1 3],'int32');
S.Srf     = fread(fid,[S.NAct 1],'float32');
%
fclose(fid);

%% Lgt File
function S = openlgt(file)
fid = fopen(file,'r');
S.FileName = file;
%
S.Dims    = fread(fid,[1 2],'int32');
S.NSeg1   = fread(fid,1,'int32');
S.NLayers = fread(fid,1,'int32');
S.Index   = fread(fid,S.Dims,'int32');
%
fclose(fid);
