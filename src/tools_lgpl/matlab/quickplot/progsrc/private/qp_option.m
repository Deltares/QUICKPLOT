function val = qp_option(FI,field,setval)
if nargin>2
    val = FI;
    val.QP_options.(field) = setval;
else
    val = [];
    if isfield(FI,'QP_options')
        if isfield(FI.QP_options,field)
            val = FI.QP_options.(field);
        end
    elseif isfield(FI,field)
        val = FI.(field);
    elseif strcmp(field,'AttribFiles') && strcmp(FI.FileType,'wlgrid') 
        val = FI.Data;
    end
end
