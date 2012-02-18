function FI = shipma(cmd,varargin)
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
        FI = LocalShipmaOpen(varargin{:});
    case 'openpar'
        FI = LocalShipmaParameterOpen(varargin{:});
    otherwise
        error('Unknown command: %s',var2str(cmd)) 
end


function FI = LocalShipmaParameterOpen(FileName,SubType)
FI.FileName = FileName;
[p,f,e] = fileparts(FileName);
if nargin<2
    e = lower(e);
    switch e
        case '.cur'
            SubType = 'current';
        case '.wav'
            SubType = 'waves';
        case '.wnd'
            SubType = 'wind';
        otherwise
            SubType = 'unknown';
    end
end
FI.SubType = SubType;
fid = fopen(FileName,'r');
i = 0;
while ~feof(fid)
    Line = fgetl(fid);
    if ~isempty(Line) && Line(1)~='*'
        if i==0
            i = i+1;
            switch SubType
                case 'current'
                    FI.WaterLevel = sscanf(Line,'%f',1);
                    continue
                case 'waves'
                    FI.WavePeriod = sscanf(Line,'%f',1);
                    continue
            end
        end
        ScaleFactor = sscanf(Line,'%f',1);
        break
    end
end
Data = fscanf(fid,'%f',[4 inf])';
FI.XY = Data(:,1:2);
switch SubType
    case 'current'
        FI.CurrentMagnitude = Data(:,3)*ScaleFactor;
        FI.CurrentToDir     = Data(:,4); % 0 = current to north
    case 'waves'
        FI.WaveHeight = Data(:,3)*ScaleFactor;
        FI.WaveToDir  = Data(:,4);
    case 'wind'
        FI.WindMagnitude = Data(:,3)*ScaleFactor;
        FI.WindFromDir   = Data(:,4); % 0 = wind from north
end
fclose(fid);



function FI = LocalShipmaOpen(FileName)
FI.FileName = FileName;
%
% First check whether this is an XML file to prevent the error message:
% [Fatal Error] FileName:1:1: Content is not allowed in prolog.
fid = fopen(FileName,'r');
firstchar = fread(fid,1,'*char');
fclose(fid);
if ~isequal(firstchar,'<')
    error('Shipma Project File should start with "<".')
end
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
FI.Sceneries.Data = getSceneryData(FI.Sceneries.XML,ProjFolder);
FI.Environments = getMembers(Children(3));
FI.Environments = getEnvironmentData(FI.Environments,ProjFolder);
FI.Manoeuvres = getMembers(Children(4));
FI.Pilots = getMembers(Children(5));
FI.TugScenarios = getMembers(Children(6));
FI.Cases = getMembers(Children(7));
FI.Cases.Data = getCaseData(FI.Cases.XML,ProjFolder);
Data = FI.Cases.Data;
for i=1:length(Data)
    Data(i).shipNr    = ustrcmpi(Data(i).shipId,{FI.Ships.Names});
    Data(i).windNr    = ustrcmpi(Data(i).windId,{FI.Environments.Winds.Names});
    Data(i).wavesNr   = ustrcmpi(Data(i).wavesId,{FI.Environments.Waves.Names});
    Data(i).currentNr = ustrcmpi(Data(i).currentId,{FI.Environments.Currents.Names});
    Data(i).swellNr   = ustrcmpi(Data(i).swellId,{FI.Environments.Swells.Names});
    Data(i).sceneryNr = ustrcmpi(Data(i).sceneryId,{FI.Sceneries.Names});
end
FI.Cases.Data = Data;


function S = getMembers(Node)
S.XML = getChildren(Node);
S.Names = getName(S.XML,true);


function Name = getName(Node,forceCell)
nNode = length(Node);
if nNode==1
    Name = char(Node.getAttribute('key'));
    if nargin>1 && forceCell
        Name = {Name};
    end
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


function Env = getEnvironmentData(Env,UnzipFolder)
for i = 1:length(Env.Names)
    envInstances = getChildren(Env.XML(i));
    if isempty(envInstances)
        envNames = {};
    else
        envNames = getName(envInstances,true);
    end
    %
    envData = [];
    nInstances = length(envInstances);
    for j = 1:nInstances
        instanceParam = getChildren(envInstances(j));
        instanceParamName = getName(instanceParam,true);
        p = 0;
        for ip = 1:length(instanceParamName)
            iPN = instanceParamName{ip};
            switch iPN
                case {'simpleSelected','fileSelected'}
                    envData(j).(iPN) = getbool(instanceParam(ip));
                case 'file'
                    FileDir = fullfile(UnzipFolder,'shi_Environment',['shi_' Env.Names{i}],['shi_' envNames{j}],'Emb_file','embCtnt');
                    embFiles = dir(FileDir);
                    FileName = fullfile(FileDir,embFiles(3).name);
                    envData(j).file = FileName;
                case 'originalPath'
                    % skip
                case 'description'
                    envData(j).description = char(instanceParam(ip).getTextContent);
                otherwise
                    p = p+1;
                    envData(j).Props(p).Quant = instanceParamName{ip};
                    unit = char(instanceParam(ip).getNodeName);
                    val = char(instanceParam(ip).getTextContent);
                    switch unit
                        case 'Double'
                            envData(j).Props(p).Unit = '';
                            envData(j).Props(p).Value = str2double(val);
                        otherwise
                            envData(j).Props(p).Unit = unit;
                            envData(j).Props(p).Value = str2double(val);
                    end
            end
        end
    end
    %
    Env.(Env.Names{i}).XML   = envInstances;
    Env.(Env.Names{i}).Names = envNames;
    Env.(Env.Names{i}).Data  = envData;
end


function bool = getbool(XML)
bool = char(XML.getTextContent);
switch bool
    case 'true'
        bool = true;
    case 'false'
        bool = false;
end

function Data = getSceneryData(Sceneries,UnzipFolder)
nSceneries = length(Sceneries);
Data(nSceneries).fairwayContourFile = [];
Data(nSceneries).banksuctionFile = [];
Data(nSceneries).bottomFile  = [];
Data(nSceneries).description = [];
for i = 1:nSceneries
    SceneryName = char(Sceneries(i).getAttribute('key'));
    %
    SceneProps = getChildren(Sceneries(i));
    ScenePropNames = getName(SceneProps,true);
    for ip = 1:length(ScenePropNames)
        switch ScenePropNames{ip}
            case {'fairwayContourFile','banksuctionFile','bottomFile'}
                % ### data is contained in an embedded file ###
                FileDir = fullfile(UnzipFolder,'shi_Sceneries',['shi_' SceneryName],['Emb_' ScenePropNames{ip}],'embCtnt');
                embFiles = dir(FileDir);
                FileName = fullfile(FileDir,embFiles(3).name);
                Data(i).(ScenePropNames{ip}) = FileName;
            case 'description'
                Data(i).description = char(SceneProps(ip).getTextContent);
        end
    end
end


function Data = getCaseData(Cases,UnzipFolder)
nCases = length(Cases);
Data(nCases).Props = [];
for i = 1:nCases
    CaseName = char(Cases(i).getAttribute('key'));
    %
    CaseProps = getChildren(Cases(i));
    CaseDef = getChildren(CaseProps(5));
    CaseComposition = getChildren(CaseDef(2));
    CaseCompositionNames = getName(CaseComposition,true);
    for ic = 1:length(CaseCompositionNames)
        switch CaseCompositionNames{ic}
            case {'shipId','windId','wavesId','currentId','swellId','sceneryId'}
                Data(i).(CaseCompositionNames{ic}) = char(CaseComposition(ic).getTextContent);
            case {'windIsSelected','wavesIsSelected', ...
                    'currentIsSelected','swellIsSelected', ...
                    'sceneryIsSelected'}
                Data(i).(CaseCompositionNames{ic}) = getbool(CaseComposition(ic));
        end
    end
    %
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
