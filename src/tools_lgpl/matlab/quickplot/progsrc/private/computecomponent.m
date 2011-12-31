function [data,scalar,vpt]=computecomponent(data,Ops)
%COMPUTECOMPONENT Compute component of vector data set.
%
%   NewData = COMPUTECOMPONENT(Data,Component)
%   where Data is a vector data structure obtained from QPREAD and
%   Component equals one of the following strings: 'magnitude',
%   'magnitude in plane', 'angle (radians)', 'angle (degrees)',
%   'x component', 'y component', 'z component', 'm component',
%   'n component', 'k component'

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

if ischar(Ops)
    vpt=Ops;
    scalar=0;
else
    vpt=Ops.vectorcomponent;
    switch lower(vpt)
        case {'vector (split x,y)'}
            N=length(data);
            data=cat(2,data,data);
            for d = 1:N
                data(d).YComp=zeros(size(data(d).YComp));
                data(N+d).XComp=data(d).YComp;
                if ~isempty(Ops.vectorcolour)
                    data(d).Val=abs(data(d).XComp);
                    data(N+d).Val=abs(data(N+d).YComp);
                end
            end
            scalar=0;
            vpt='vector';
            return
        case {'vector (split m,n)'}
            N=length(data);
            data=cat(2,data,data);
            for d = 1:N
                data(d).XComp=real(data(d).XComp);
                data(d).YComp=real(data(d).YComp);
                data(N+d).XComp=imag(data(N+d).XComp);
                data(N+d).YComp=imag(data(N+d).YComp);
                if ~isempty(Ops.vectorcolour)
                    data(d).Val=sqrt(data(d).XComp.^2+data(d).YComp.^2);
                    data(N+d).Val=abs(data(N+d).YComp.^2+data(N+d).YComp.^2);
                end
            end
            scalar=0;
            vpt='vector';
            return
        case {'vector','patch centred vector'}
            scalar=0;
            if ~isempty(Ops.vectorcolour)
                vpt=Ops.vectorcolour;
            else
                return
            end
        otherwise
            scalar=1;
    end
end
for d=1:length(data)
    switch lower(vpt)
        case {'vector','vector (split x,y)'}
        case 'magnitude'
            data(d).Val=data(d).XComp.^2;
            if isfield(data,'YComp')
                data(d).Val=data(d).Val+data(d).YComp.^2;
            end
            if isfield(data,'ZComp')
                data(d).Val=data(d).Val+data(d).ZComp.^2;
            end
            data(d).Val=sqrt(data(d).Val);
        case 'magnitude in plane'
            if isfield(data,'XComp') & size(data(d).XComp,1)>1
                data(d).Val=data(d).XComp.^2;
                if isfield(data,'YComp') & size(data(d).YComp,2)>1
                    data(d).Val=data(d).Val+data(d).YComp.^2;
                end
            elseif isfield(data,'YComp') & size(data(d).YComp,2)>1
                data(d).Val=data(d).YComp.^2;
            end
            if isfield(data,'ZComp') & size(data(d).ZComp,3)>1
                data(d).Val=data(d).Val+data(d).ZComp.^2;
            end
            data(d).Val=sqrt(data(d).Val);
        case 'angle (radians)'
            %data(d).Val=atan2(data(d).YComp,data(d).XComp); % mathematical convention
            data(d).Val=atan2(data(d).XComp,data(d).YComp); % Nautical convention
            data(d).Units='rad';
            vpt='angle';
        case 'angle (degrees)'
            %data(d).Val=(180/pi)*atan2(data(d).YComp,data(d).XComp); % mathematical convention
            data(d).Val=(180/pi)*atan2(data(d).XComp,data(d).YComp); % Nautical convention
            data(d).Units='deg';
            vpt='angle';
        case 'x component'
            data(d).Val=data(d).XComp;
        case 'y component'
            data(d).Val=data(d).YComp;
        case 'z component'
            data(d).Val=data(d).ZComp;
        case 'm component'
            data(d).Val=data(d).XComp; %MComp
        case 'n component'
            data(d).Val=data(d).YComp; %NComp
        case 'k component'
            data(d).Val=data(d).ZComp; %KComp
        case 'normal component' % only for a vertical slice
            if  size(data(d).Val,1)>1
                data(d).Val=data(d).YComp; %NComp
            else
                data(d).Val=data(d).XComp; %MComp
            end
        otherwise
            ui_message('error',sprintf('Unexpected colour/plot type encountered: %s.',vpt));
            scalar=0;
    end
end
