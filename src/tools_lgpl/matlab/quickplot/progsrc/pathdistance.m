function d0=pathdistance(x0,y0,z0),
%PATHDISTANCE Computes the distance along a path.
%   Computes the distance along the path from the first
%   point for every point on the path.
%
%   Distance=PATHDISTANCE(XCoord,YCoord,ZCoord)
%   Distance=PATHDISTANCE(XCoord,YCoord)
%   Distance=PATHDISTANCE(Coord)
%
%   NaNs are skipped in the computation of the path length.

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

d0=repmat(NaN,size(x0));

if nargin==1,
    iprev=min(find(~isnan(x0)));
    d0(iprev)=0;
    for i=(iprev+1):length(x0),
        if isnan(x0(i)),
            d0(i)=NaN;
        else,
            d0(i)=d0(iprev)+abs(x0(i)-x0(iprev));
            iprev=i;
        end;
    end;
elseif nargin==2,
    iprev=min(find(~isnan(x0) & ~isnan(y0)));
    d0(iprev)=0;
    for i=(iprev+1):length(x0),
        if isnan(x0(i)) | isnan(y0(i)),
            d0(i)=NaN;
        else,
            d0(i)=d0(iprev)+sqrt((x0(i)-x0(iprev))^2+(y0(i)-y0(iprev))^2);
            iprev=i;
        end;
    end;
elseif nargin==3,
    iprev=min(find(~isnan(x0) & ~isnan(y0) & ~isnan(z0)));
    d0(iprev)=0;
    for i=(iprev+1):length(x0),
        if isnan(x0(i)) | isnan(y0(i)) | isnan(z0(i)),
            d0(i)=NaN;
        else,
            d0(i)=d0(iprev)+sqrt((x0(i)-x0(iprev))^2+(y0(i)-y0(iprev))^2+(z0(i)-z0(iprev))^2);
            iprev=i;
        end;
    end;
end;
