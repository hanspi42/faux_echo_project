function [N_opt,D_opt,N_WL,N_FL,D_WL,D_FL] = findOptimizedCoefficients(N,D,error, max_N)
%Searches for the best representation of fixed-point filter coefficients

len_N = findMinWordLenght(N,error,max_N);
len_D = findMinWordLenght(D,error,max_N);
N_opt = sfi(N,len_N); 
N_WL = N_opt.WordLength;
N_FL = N_opt.FractionLength;
D_opt = sfi(D,len_D);
D_WL = D_opt.WordLength;
D_FL = D_opt.FractionLength;

end

