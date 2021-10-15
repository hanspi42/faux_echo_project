function [N_min] = findMinWordLenght(input,error,max_N)
%Searches for the required Word Length of a signed fixed-point number until
%the quantization error is below a specified error.
%   input = Array of real-world values, Dim 1xN
%   error = Relative error in per cent, Dim 1x1
%   max_N = Maximum word length, Dim 1x1
%   N_min = Minimum number of bits to fulfil the error requirements. Dim
%   1x1
%   Returns -1 if max_N does not satisfy the condition.

error_percent = error;
max_bit = max_N;
k = 2;                   % Min. 2 bit for signed data types
res = zeros(1,max_bit);  % Store the highest relative error of each iteration
while max_bit >= k
   input_sfi =  sfi(input,k);
   input_approx = input_sfi.data;
   e_abs = input - input_approx;
   e_rel = e_abs./input;
   e_percent = abs(e_rel)*100;
   e_max = max(e_percent);
   res(k) = e_max;
   k = k+1;
end

%n = linspace(1,max_bit,max_bit);
%visualize = [n', res']

N_min = -1;
for k=2:max_bit
   if (res(k) < error_percent)
       N_min = k;
       break
   end
end

end

