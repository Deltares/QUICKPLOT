function FI = shipma(cmd,FileName)
%SHIPMA Read Shipma project (and embedded) files. (BETA VERSION)
%   STRUCT = SHIPMA('open',FILENAME) opens the specified Shipma file, and
%   (partly) reads the associated embedded data files.
%
%   See also TEKAL, SAMPLES, DELWAQ.

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

switch lower(cmd)
    case 'open'
        FI = LocalShipmaOpen(FileName);
    otherwise
        error('Unknown command: %s',var2str(cmd)) 
end


function FI = LocalShipmaOpen(FileName)
FI.FileName = FileName;
%
[p,f,e]=fileparts(FI.FileName);
FI.UnzipFolder = [p filesep f '_' e(2:end) '.emb'];
%
FI.XML = xmlread(FileName);
Doc = FI.XML.getFirstChild;
if FI.XML.getLength~=1 || ...
        ~isequal(char(Doc.getNodeName),'documentTag') || ...
        ~isequal(char(Doc.getAttribute('key')),'Shipma Projects')
    error('First level of Shipma XML file should be a single documentTag with key=Shipma Projects')
end
IntProp = Doc.getFirstChild;
Proj = Doc.getLastChild;
if Doc.getLength~=2 || ...
        ~isequal(char(IntProp.getNodeName),'internal_properties') || ...
        ~isequal(char(Proj.getNodeName),'shipmaProject')
    error('Second level of Shipma XML file should be an internal_properties node and a shipmaProject node')
end
FI.TempFilePath = char(IntProp.getFirstChild.getTextContent);
%
Children = getChildren(Proj);
FI.ProjectName = getName(Proj);
ProjFolder = fullfile(FI.UnzipFolder,['shi_' FI.ProjectName]);
FI.Ships = getMembers(Children(1));
FI.Ships.Data = getShipData(FI.Ships.XML);
FI.Sceneries = getMembers(Children(2));
FI.Environments = getMembers(Children(3));
FI.Manoeuvres = getMembers(Children(4));
FI.Pilots = getMembers(Children(5));
FI.TugScenarios = getMembers(Children(6));
FI.Cases = getMembers(Children(7));
FI.Cases.Data = getCaseData(FI.Cases.XML,ProjFolder);
1


function S = getMembers(Node)
S.XML = getChildren(Node);
S.Names = getName(S.XML);


function Name = getName(Node)
nNode = length(Node);
if nNode==1
    Name = char(Node.getAttribute('key'));
else
    Name = cell(1,nNode);
    for i = 1:nNode
        Name{i} = char(Node(i).getAttribute('key'));
    end
end


function Children = getChildren(Node)
nChild = Node.getLength;
c = cell(1,nChild);
c{1} = Node.getFirstChild;
for i = 2:nChild
    c{i} = c{i-1}.getNextSibling;
end
Children = [c{:}];


function Data = getCaseData(Cases,UnzipFolder)
nCases = length(Cases);
Data(nCases).Props = [];
for i = 1:nCases
    CaseName = char(Cases(i).getAttribute('key'));
    FileName = fullfile(UnzipFolder,'shi_Cases',['shi_' CaseName],'Shi_results','Wor_workDir','embCtnt','containedFiles','track.his');
    Data(i).TimeSeries = delwaq('open',FileName);
end


function Data = getShipData(Ships)
nShips = length(Ships);
Data(nShips).Props = [];
for i = 1:nShips
    Data(i).Props = getShipProps(Ships(i));
end


function ShipProps = getShipProps(Ship)
Props = getChildren(Ship);
nProp = length(Props);
ShipProps(nProp).Unit = [];
for p = 1:nProp
    ShipProps(p).Unit = char(Props(p).getTagName);
    ShipProps(p).Quant = char(Props(p).getAttribute('key'));
    switch ShipProps(p).Quant
        case {'frontalArea','lateralArea','liftArea','yawRefLength', ...
                'heelRefLength','trimRefLength','loa','lpp','beam', ...
                'draught','mass','momOfInertia','xCog', ...
                'manoeuvringSpeed','maxRudderAngle','maxRudderRate', ...
                'maxRevAhead','maxRevAstern','maxVelocityChangeRPM', ...
                'maxPropellerAcceleration'}
            ShipProps(p).Value = str2double(char(Props(p).getTextContent));
        case 'contour'
            Contour = getChildren(Props(p)); % String and Points
            Points = getChildren(Contour(2));
            nPoints = length(Points);
            contour = zeros(nPoints,2);
            for i=1:nPoints
                Point = getChildren(Points(i));
                contour(i,1) = str2double(char(Point(1).getTextContent));
                contour(i,2) = str2double(char(Point(2).getTextContent));
            end
            ShipProps(p).Value = contour;
        otherwise
            if isequal(class(Props(p).getFirstChild),'org.apache.xerces.dom.DeferredTextImpl')
                ShipProps(p).Value = char(Props(p).getTextContent);
            else
                ShipProps(p).Value = getChildren(Props(p));
            end
    end
end
