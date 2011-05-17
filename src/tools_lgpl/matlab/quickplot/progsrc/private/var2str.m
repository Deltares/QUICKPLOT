function Str=var2str(X)
%VAR2STR Generic "display" function with string output.
%   STRING = VAR2STR(VARIABLE) works similar to DISP(VARIABLE) but returns
%   the resulting text as string.

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

switch class(X)
    case 'struct'
        Str=cat(1,{[LocalSize(X) ' struct array with fields:']},fieldnames(X));
    case 'char'
        if ndims(X)<=2
            Str=X;
        else
            Str=[LocalSize(X) ' char array'];
        end
    case {'single','double','logical', ...
          'int8','int16','int32','int64', ...
          'uint8','uint16','uint32','uint64'}
        if ndims(X)<=2 && ~isempty(X)
            if numel(X)<100
                Str=num2str(X);
            else
                Str=[LocalSize(X) ' ' class(X) ' array'];
            end
        else
            Str=[LocalSize(X) ' ' class(X) ' array'];
        end
    case 'cell'
        Str=[LocalSize(X) ' cell array'];
        if iscellstr(X) && sum(size(X)>1)<2 && ~isempty(X)
            Str={[Str ' containing']};
            Str{2}=sprintf('''\n''%s',X{:});
            Str{2}=Str{2}([3:end 1:2]);
        end
    otherwise
        Str=[LocalSize(X) ' ' class(X) ' array'];
end


function Str=LocalSize(X)
Sz=size(X);
Str=[sprintf('%i',Sz(1)) sprintf('x%i',Sz(2:end))];
