function qp_updatescroller(hNew,pfig)
%QP_UPDATESCROLLER Update list of items/dimensions that can be animated.

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

T_=1; ST_=2; M_=3; N_=4; K_=5;
DimStr={'subfield ','timestep ','station ','M=','N=','K='};

UDs = get(hNew,'userdata');
if ~iscell(UDs)
    UDs = {UDs};
end
UDs(cellfun('isempty',UDs)) = [];
for i = 1:length(UDs)
    UD = UDs{i};
    ObjTag = get(hNew(i),'tag');

    Info = UD.PlotState.FI;
    DomainNr = UD.PlotState.Domain;
    Props = UD.PlotState.Props;
    selected = UD.PlotState.Selected;
    subf = UD.PlotState.SubField;

    [Chk,subfs]=qp_getdata(Info,DomainNr,Props,'subfields');
    [Chk,sz]=qp_getdata(Info,DomainNr,Props,'size');
    CanAnim=0;
    Obj.SubfRange=[];
    Obj.TRange=[];
    Obj.StRange=[];
    Obj.MRange=[];
    Obj.NRange=[];
    Obj.KRange=[];
    if Chk
        if length(subfs)>1 && length(subf)==1 && ~isequal(subf,0)
            Obj.SubfRange=[1 length(subfs)];
            CanAnim=1;
        end
        if Props.DimFlag(T_) && (sz(T_)>1) && length(selected{T_})==1 && ~isequal(selected{T_},0)
            Obj.TRange=[1 sz(T_)];
            CanAnim=1;
        end
        if Props.DimFlag(ST_) && (sz(ST_)>1) && length(selected{ST_})==1 && ~isequal(selected{ST_},0)
            Obj.StRange=[1 sz(ST_)];
            CanAnim=1;
        end
        if Props.DimFlag(M_) && (sz(M_)>1) && length(selected{M_})==1 && ~isequal(selected{M_},0)
            Obj.MRange=[1 sz(M_)];
            CanAnim=1;
        end
        if Props.DimFlag(N_) && (sz(N_)>1) && length(selected{N_})==1 && ~isequal(selected{N_},0)
            Obj.NRange=[1 sz(N_)];
            CanAnim=1;
        end
        if Props.DimFlag(K_) && (sz(K_)>1) && length(selected{K_})==1 && ~isequal(selected{K_},0)
            Obj.KRange=[1 sz(K_)];
            CanAnim=1;
        end
    end

    if CanAnim && ishandle(pfig)
        animslid=findobj(pfig,'tag','animslid');
        if isempty(animslid)
            qp_figurebars(pfig)
            qp_createscroller(pfig)
            animslid=findobj(pfig,'tag','animslid');
        end
        animpush=findobj(pfig,'tag','animpush');
        set(animpush,'enable','on')
        uicm=findobj(pfig,'tag','animpushuicontextmenu');
        hAnimOptChecked=findall(get(uicm,'children'),'checked','on');
        if i==1
            AS=[];
            set(hAnimOptChecked,'checked','off')
        else
            AS=get(animslid,'userdata');
        end
        it=uimenu('label',Props.Name,'parent',uicm,'userdata',ObjTag);
        AnimOpt=[]; hAnimOpt=[];
        if ~isempty(Obj.TRange)
            AnimLoc=[T_ Obj.TRange(2)];
            hMenu=uimenu('label','time','parent',it,'userdata',AnimLoc,'callback','d3d_qp animselect');
            if isempty(AnimOpt), AnimOpt=AnimLoc; hAnimOpt=hMenu; end
        end
        if ~isempty(Obj.StRange)
            AnimLoc=[ST_ Obj.StRange(2)];
            hMenu=uimenu('label','station','parent',it,'userdata',AnimLoc,'callback','d3d_qp animselect');
            if isempty(AnimOpt), AnimOpt=AnimLoc; hAnimOpt=hMenu; end
        end
        if ~isempty(Obj.MRange)
            AnimLoc=[M_ Obj.MRange(2)];
            hMenu=uimenu('label','M','parent',it,'userdata',AnimLoc,'callback','d3d_qp animselect');
            if isempty(AnimOpt), AnimOpt=AnimLoc; hAnimOpt=hMenu; end
        end
        if ~isempty(Obj.NRange)
            AnimLoc=[N_ Obj.NRange(2)];
            hMenu=uimenu('label','N','parent',it,'userdata',AnimLoc,'callback','d3d_qp animselect');
            if isempty(AnimOpt), AnimOpt=AnimLoc; hAnimOpt=hMenu; end
        end
        if ~isempty(Obj.KRange)
            AnimLoc=[K_ Obj.KRange(2)];
            hMenu=uimenu('label','K','parent',it,'userdata',AnimLoc,'callback','d3d_qp animselect');
            if isempty(AnimOpt), AnimOpt=AnimLoc; hAnimOpt=hMenu; end
        end
        if ~isempty(Obj.SubfRange)
            AnimLoc=[0 Obj.SubfRange(2)];
            hMenu=uimenu('label','subfield','parent',it,'userdata',AnimLoc,'callback','d3d_qp animselect');
            if isempty(AnimOpt), AnimOpt=AnimLoc; hAnimOpt=hMenu; end
        end
        sstep=[min(1/(AnimOpt(2)-1),.1) min(10/(AnimOpt(2)-1),.9)];
        AS(end+1).Fld=AnimOpt(1);
        AS(end).Tag=ObjTag;
        if length(AS)>1
            if ~isequal(AS(end).Fld,AS(end-1).Fld)
                AS = AS(end);
                set(hAnimOptChecked,'checked','off')
            end
        end
        t_=AnimOpt(1);
        if t_==0
            t=subf{1};
        else
            t=selected{t_};
        end
        set(animslid,'userdata',AS,'value',1,'sliderstep',sstep,'Max',AnimOpt(2),'enable','on','value',t)
        set(hAnimOpt,'checked','on')
        %
        Str=sprintf('%i',t);
        if t_==0
            [Chk,sflds] = qp_getdata(Info,DomainNr,Props,'subfields',t);
            if Chk
                Str=sflds{1};
            end
        end
        set(animslid,'tooltip',[DimStr{t_+1},Str]);
    end
end
