function url = uigeturl
%UIGETLINK Open URL dialog box.

%----- LGPL --------------------------------------------------------------------
%                                                                               
%   Copyright (C) 2011-2014 Stichting Deltares.                                     
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

pos = qp_getscreen;
sz  = [500 470];
pos = floor([pos(1:2)+pos(3:4)/2-sz/2 sz]);

Fig = qp_uifigure('Select URL to open ...','','SelectURL',pos);
uicontrol('Parent',Fig, ...
    'Callback',@populate_list, ...
    'Style','pushbutton', ...
    'Enable','on', ...
    'Horizontalalignment','left', ...
    'Position',[11 441 pos(3)-20 20], ...
    'tag','Populate', ...
    'String','Browse list of THREDDS catalogs');
uicontrol('Parent',Fig, ...
    'KeypressFcn',@browse_list, ...
    'Callback',@browse_list, ...
    'Style','listbox', ...
    'Enable','off', ...
    'Max',2, ...
    'Horizontalalignment','left', ...
    'Position',[11 71 pos(3)-20 360], ...
    'tag','List', ...
    'fontname','Courier', ...
    'String','');
hURL = uicontrol('Parent',Fig, ...
    'Callback','', ...
    'Style','edit', ...
    'Backgroundcolor',[1 1 1], ...
    'Enable','on', ...
    'Horizontalalignment','left', ...
    'Position',[11 41 pos(3)-20 20], ...
    'tag','URL', ...
    'String','http://');
uicontrol('Parent',Fig, ...
    'Callback','delete(gcbf)', ...
    'Style','pushbutton', ...
    'Enable','on', ...
    'Position',[pos(3)-80 11 70 20], ...
    'tag','Cancel', ...
    'String','Cancel');
uicontrol('Parent',Fig, ...
    'Callback','set(gcbf,''Visible'',''off'')', ...
    'Style','pushbutton', ...
    'Enable','on', ...
    'Position',[pos(3)-160 11 70 20], ...
    'tag','Open', ...
    'String','Open');
set(Fig,'Visible','on')

waitfor(Fig,'Visible','off')
if ishandle(Fig)
    url = get(hURL,'string');
else
    url = 0;
end


function populate_list(h,arg2)
server = 'http://opendap.deltares.nl/thredds/catalog.xml';
set(get(h,'Parent'),'pointer','watch')
drawnow
flds = read_server(server,'','');
set(get(h,'Parent'),'pointer','arrow')
if ~isempty(flds)
    list = findall(get(h,'Parent'),'tag','List');
    set(list,'enable','on','string',flds(:,1),'userdata',flds,'backgroundcolor',[1 1 1])
    set(h,'enable','off')
end


function browse_list(h,event)
if isempty(event)
    % mouse
    key = get(get(h,'Parent'),'selectiontype');
else
    key = event.Key;
end
j=get(h,'value');
UD=get(h,'userdata');
open = strcmp(key,'open') | strcmp(key,'rightarrow');
close = strcmp(key,'open') | strcmp(key,'leftarrow');
if close && iscell(UD{j,2}) && strcmp(UD{j,2}{1},'opened')
    % close
    UD = recursive_close(UD,j);
elseif open
    space = ['  ' UD{j,3}];
    if iscell(UD{j,2})
        if strcmp(UD{j,2}{1},'urlpath')
            file = UD{j,2}{2};
            server = UD{j,4};
            i = strfind(server,'/');
            file = [server(1:i(3)) 'thredds/dodsC/' file];
            file = strrep(file,' ','%20');
            hFig = get(h,'Parent');
            hURL = findall(hFig,'tag','URL');
            if strcmp(get(hURL,'string'),file)
                set(hFig,'visible','off')
            else
                set(hURL,'string',file)
            end
        end
        return
    elseif ischar(UD{j,2})
        % read new server
        server = UD{j,2};
        set(get(h,'Parent'),'pointer','watch')
        drawnow
        flds = read_server(server,space,UD{j,4});
        if size(flds,1)==1 && strcmp(UD{j,1},flds{1,1}(3:end))
            flds = expand_dataset(flds{2},space,flds{4});
        end
        set(get(h,'Parent'),'pointer','arrow')
        if isempty(flds)
            return
        end
        UD{j,2} = {'opened' j+1:j+size(flds,1) server};
        UD = cat(1,UD(1:j,:),flds,UD(j+1:end,:));
    else
        % expand dataset
        elm = UD{j,2};
        flds = expand_dataset(elm,space,UD{j,4});
        UD{j,2} = {'opened' j+1:j+size(flds,1) elm};
        UD = cat(1,UD(1:j,:),flds,UD(j+1:end,:));
    end
else
    return
end
set(h,'string',UD(:,1),'userdata',UD)


function UD = recursive_close(UD,j)
items = UD{j,2}{2};
for i = items
    if iscell(UD{i,2}) && strcmp(UD{i,2}{1},'opened')
        UD = recursive_close(UD,i);
    end
end
UD(items,:) = [];
UD{j,2} = UD{j,2}{3};


function flds = read_server(server,space,orgserver)
flds = [];
if length(server)<4 || ~strcmpi(server(1:4),'http')
    if length(server)>1 && strcmp(server(1),'/')
        i = strfind(orgserver,'/');
        server = [orgserver(1:i(3)-1) server];
    else
        p = fileparts(orgserver);
        server = [p '/' server];
    end
end
try
    X = xmlread(server);
catch
    ui_message('error','Error while contacting:\n%s',server)
    return
end
catalog = getChildren(X);
if ~strcmp(catalog.getNodeName,'catalog')
    ui_message('error','Unable to locate <catalog> field:\n%s',server)
    return
end
elm = getChildren(catalog);
flds = expand_dataset(elm,space,server);


function flds = expand_dataset(elm,space,server)
nrec = 0;
for i = 1:length(elm)
    switch char(elm(i).getNodeName)
        case {'dataset','catalogRef'}
            nrec = nrec+1;
    end
end
flds = cell(nrec,4);
nrec = 0;
for i = 1:length(elm)
    switch char(elm(i).getNodeName)
        case 'dataset'
            nrec = nrec+1;
            urlPath = char(elm(i).getAttribute('urlPath'));
            if isempty(urlPath)
                flds{nrec,1} = [space '+ ' char(elm(i).getAttribute('name'))];
                flds{nrec,2} = getChildren(elm(i));
            else
                flds{nrec,1} = [space '  ' char(elm(i).getAttribute('name'))];
                flds{nrec,2} = {'urlpath' urlPath};
            end
            flds{nrec,3} = space;
            flds{nrec,4} = server;
        case 'catalogRef'
            nrec = nrec+1;
            flds{nrec,1} = [space '+ ' char(elm(i).getAttribute('xlink:title'))];
            flds{nrec,2} = char(elm(i).getAttribute('xlink:href'));
            flds{nrec,3} = space;
            flds{nrec,4} = server;
        otherwise % #text
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
