while input('Continue? (Y/N)','s') == 'Y'
InputValue = input('Damped(D) or Undamped(U)?\n','s');
    try
        [mass,AverageMass,Delta] = CalculateDeltaMass(InputValue);
    catch
        disp('Error, try again')
        InputValue = input('Damaged(D) or Undamaged(U)?\n','s');
        [mass,AverageMass,Delta] = CalculateDeltaMass(InputValue);
    end
end
