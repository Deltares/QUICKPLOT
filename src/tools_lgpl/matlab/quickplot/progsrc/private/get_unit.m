function unit = get_unit(Info)
unit = [];
if ~isempty(Info.Attribute)
    Attribs = {Info.Attribute.Name};
    j = strmatch('units',Attribs,'exact');
    if ~isempty(j)
        unit = Info.Attribute(j).Value;
        units = {'degrees_east','degree_east','degreesE','degreeE', ...
            'degrees_north','degree_north','degreesN','degreeN'};
        if ismember(unit,units)
            unit = 'deg';
        end
    end
end
