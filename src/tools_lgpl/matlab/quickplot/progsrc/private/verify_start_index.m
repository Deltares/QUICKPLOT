function start_index = verify_start_index(istart, start_index, minIndex, maxIndex, limitIndex, location, variable)
if isempty(istart)
    if minIndex == 1 && maxIndex == limitIndex
        start_index = 1;
        ui_message('warning','No start_index found on %s.\nDefault value is 0, but data suggest otherwise.\nUsing start_index=1.', variable)
    else
        start_index = 0;
    end
else
    if minIndex-start_index+1 < 1
        error('File specifies start_index %g for %s, but lowest %s index in file is %g.', start_index, variable, location, minIndex)
    elseif maxIndex-start_index+1 > limitIndex
        error('File specifies start_index %g for %s and the largest %s index in file is %g, but the last %s is only %g.', start_index, variable, location, maxIndex, location, limitIndex)
    end
end
