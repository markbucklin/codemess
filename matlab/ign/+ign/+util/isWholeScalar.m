function flag = isWholeScalar( num )

flag = ...
	isnumeric(num) && ...
	isscalar(num) && ...
	(mod(num,1) == 0) && ...
	(num >= 0);