function make_ecoplot(basedir,varargin)
%MAKE_ECOPLOT Compile ECOPLOT executable
%   Compile MATLAB code to ECOPLOT executable
%
%   MAKE_ECOPLOT(BASEDIR)
%   Use specified directory instead of current directory as base directory

%   $Id$

curdir=pwd;
addpath(curdir)
if matlabversionnumber<7.09
    error('Invalid MATLAB version. Use MATLAB R2009b (7.9) or higher for compiling Delft3D-ECOPLOT!')
end
if ~exist('mcc')
    error('Cannot find MATLAB compiler. Use another MATLAB installation!')
end
if nargin>0
    cd(basedir);
end
try
    err=localmake(varargin{:});
catch
    err=lasterr;
end
if nargin>0
    cd(curdir);
end
rmpath(curdir)
if ~isempty(err)
    error(err)
end


function err=localmake(qpversion,T)
err='';
if ~exist('progsrc','dir')
    err='Cannot locate source'; return
end
sourcedir=[pwd,filesep,'progsrc'];
disp('Copying files ...')
if ~exist([pwd,filesep,'ecoplot'])
    [success,message] = mkdir('ecoplot');
    if ~success,
        err=message;
        return
    end
end
cd('ecoplot');
diary make_ecoplot_diary
if isunix
    unix('cp -rf ../progsrc/* .');
    unix('mv compileonly/* .');
else
    [s,msg]=dos('xcopy "..\progsrc\*.*" "." /E /Y');
    if s==0
        [s,msg]=dos('move compileonly\*.*  .');
    end
    if s~=0
        error(msg)
    end
end
%
copyfile('../../../../third_party_open/netcdf/matlab/netcdfAll-4.1.jar','.')
addpath ../../../../third_party_open/netcdf/matlab/mexnc
addpath ../../../../third_party_open/netcdf/matlab/snctools
%
if nargin<2
    qpversion=read_identification(sourcedir,'d3d_qp.m');
    T=now;
end
fprintf('\nBuilding Delft3D-ECOPLOT version %s\n\n',qpversion);
TStr = datestr(T);
fstrrep('d3d_qp.m','<VERSION>',qpversion)
fstrrep('d3d_qp.m','<CREATIONDATE>',TStr)
fstrrep('wl_identification.c','<VERSION>',qpversion)
fstrrep('wl_identification.c','<CREATIONDATE>',TStr)
make_eco_exe
X={'*.asv'
    '*.bak'
    '*.m'
    '*.c'
    '*.cpp'
    '*.h'
    '*.o'
    '*.obj'
    '*.a'
    '*.lib'
    '*.scc'
    'private'
    'compileonly'
    '@qp_data'
    '@qp_data_resource'};
if isunix
    X=cat(1,X,{'*.dll'
        '*.mexw*'});
else
    X=cat(1,X,{'*.mexglx'
        '*.mexa64'
        '*.exp'});
end
cleanup(X)
diary off
cd ..