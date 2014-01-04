function make_all
%MAKE_ALL Build various tools based on the QUICKPLOT source
%   Builds
%     * Delft3D-MATLAB interface
%     * QUICKPLOT
%     * ECOPLOT
%   all with exactly the same version number.

%   $Id$

curdir = pwd;
sourcedir=[curdir,filesep,'progsrc'];
qpversion=read_identification(sourcedir,'d3d_qp.m');
T=now;
make_quickplot(curdir,qpversion,T)
make_ecoplot(curdir,qpversion,T)
make_d3dmatlab(curdir,qpversion,T)