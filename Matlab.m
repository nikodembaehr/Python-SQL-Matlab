clear all
close all
clc

% Group ...:
% 1. Nikodem Baehr (2076515)
% 2. Rudolfs Jansons (2080485)
% 3. Dans Lismanis (2080683)
% 4. Andrei Agapie (2075694)

%% Question B)
%It is mandatory to store the parameters of the distributions in structure p
p.a = 1; p.b = 10; p.ell = 1; p.u = 10; p.mu = 1; p.sigma = 5;

% Define the parameters
n = 9;
m = 27;
%getting pdfs 
%for halfnormal i took the definiton in matlab website 
half_normalpdf=@(x) (sqrt(2 / pi)*(1 / (sqrt(p.sigma)))) * exp(-(1/2) * ((x - p.mu) / sqrt(p.sigma)).^2).* (x >=p.mu);
gammapdf=@(x) gampdf(x, p.a, p.b);
uniformpdf=@(x) unifpdf(x, p.ell, p.u);
%creting array to store the pdfs in
F = cell(1, m);
%creating loop to assgine the pdfs to correct boxes
for i = 1:m
    if mod(i-1,n) < 3
        F{i} = half_normalpdf;
    elseif mod(i-1, n) < 6
        F{i} =gammapdf;
    else
        F{i} = uniformpdf;
    end
end

% Call the calculate_thresholds function
[T, T0] = calculate_thresholds(F);
disp(['The values of tresholds for each box: ', num2str(T)]);
disp(['The expected payoff is ', num2str(T0)]);
%% Question E)


%% Question F)
%calls function from a to get expected payoff T0 as a2 using uniform (0,20)
pdf=arrayfun(@(x) @(x) unifpdf(x, 0, 15), 1:25, 'UniformOutput', false);
[~,A]=calculate_thresholds(pdf);
%Sets B as value in e where alpha=1
B=0.4025;
C=abs(A-B);
%Prinsts the text
fprintf("The difference between the optimal expected payoff %f of the gambler and the simulated average optimal payoff %f is %f",a2,B,C);

%% Question I)
%Creates a realization matrix V
V = 0 + (15 - 0) * rand(25, 10000);

%creates a pdf vector of size 25x10000 using Unif(0,15)
pdf = arrayfun(@(x) @(x) unifpdf(x, 0, 15), 1:25, 'UniformOutput', false);

%Creates a cost vector
c = (1:25)/25 * 15/2;

%Calculates optimal thresholds using 1.1 a and vector consisting of 25
%Unif(0,15) pdfs
[T,T0]=calculate_thresholds(pdf);

%Calls function from h using optimal thresholds, uniform realizations and
%cost vector.
[opB,utility]=h(T,c,V);

%% Question K)
p.mu=1; p.sigma=11;
F=makedist("HalfNormal","mu",p.mu,"sigma",p.sigma);
n=100;
k=66;
med=mediian(F,n,k);

disp(['Threshold T^k for n = ', num2str(n), ' and k = ', num2str(k), ' is: ', num2str(med)]);


%% Question L)
n=100;
nsims=1000000;
p.mu=0; p.sigma=1;
dist1=makedist('Normal','mu',p.mu,'sigma',p.sigma); %symmetric
p.a=2; p.b=1;
dist2=makedist('Gamma','a',p.a,'b',p.b); %right skewed
p.a=20; p.b=2;
dist3=makedist('Beta','a',p.a,'b',p.b); % left skewed
bestk1 = kbest(dist1, nsims, n);
bestk2 = kbest(dist2, nsims, n);
bestk3 = kbest(dist3, nsims, n);
fprintf('Normal distributions optimal k-th order statistics is %d\n', bestk1);
fprintf('Gamma distributions optimal k-th order statistics is %d\n', bestk2);
fprintf('Beta distributions optimal k-th order statistics is %d\n', bestk3); 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Below, the functions from a),c),d),g),h),j) have to be implemented %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Question A): Computing optimal thresholds 
function [T, T0] = calculate_thresholds(F)
% getting nr of boxes n
    n = length(F); 
    % make an array to store values of tresholds
    T = zeros(1, n); 
    %you allways pcik last box no matter the payoff so  T(n)=0 so no need
    %to adjust it
    %caculating theshold of second to last box
    T(n-1) = integral(@(x) x.*F{n}(x), -Inf, Inf); 
     %start from n-2 as the 2 last boxes thersholds are caculated
    %doing it recursevly and implamenting the given formula
    for i = n-2:-1:1
        %definfing function to get the expected value of the given function
        %in the assigment
        func= @(x) max(x, T(i+1)).*F{i}(x);
        % calculating threshold
        T(i) = integral(func, -Inf, Inf); 
    end
    %caculating the expected payoff explicitly
    T0 = integral(@(x) max(x, T(1)).*F{1}(x), -Inf, Inf); 
   
end

%% Question C): Box selection based on thresholds 


%% Question D): Value generation 


%% Question G): Utility computation 
function [meanutility] = g(beta, T, c, V)
    % Get the number of entries (columns) of the realization matrix
    [~, d] = size(V);

    % Creates vectors for index, payoffs and utilities to speed up
    % computations
    index = zeros(1, d);
    payoff = zeros(1, d);
    utility = zeros(1, d);

    % Calculate index, payoff, and utility for each entry using vectorized operations
    for i = 1:d
        % Thresholds are found
        thresholds = T' .* beta;

        % Find index where realization matrix satisfies thresholds and 
        % their respective payoffs
        [index(i), ~] = find(V(:, i) > thresholds, 1);
        payoff(i) = V(index(i), i);

        % Calculate utility for each entry
        utility(i) = payoff(i) - c(index(i));
    end

    % Calculate the mean utility for all d entries
    meanutility = mean(utility);
end


%% Question H): Maximization over beta's
function [optB, utility]=h(T,c,V)
    %Objective function to be minimized using fminsearch, which is the
    %negative of utility function
    obj= @(beta) (-g(beta,T,c,V));

    %Intial guess of beta needed for fminsearch
    [n,~]=size(V);
    inital_beta=ones(n,1);

    %Calls fminsearch to maximise utility (or minimise -utility) with
    %respect to beta to obtain optimal value of beta.
    optB=fminsearch(obj,inital_beta);
    
    %Calls g2 to calculate utility using optimal beta
    utility=g(optB,T,c,V);
end

%% Question J): Computing median of k-th order statistic
function cdf_xk=cdf_korder(F,n,k,x)
%cdf_korder inputs a probability distribtuion F,n is the sample size, k is
% the order statistic and x is the CDF's value to be calculated at
    pas_tri=arrayfun(@(x) nchoosek(n, x), k:n);
    %getting the coefficients from pascal triangle (nchoosek) in an array with a
    %n-k length
    cdf_xk=sum(pas_tri.*(F.cdf(x).^(k:n)).*((1-F.cdf(x)).^((n-k):-1:0)));
    %cdf_xk calculates the cdf given the coefficients from the pascal
    %triangle, a standard formula for the cumulative distribution function
end

function med=mediian(F,n,k)
%function mediian(F,n,k) calculates the median of the kth order statistics
%from the iid sample with size n given the F distribution
    func=@(x) cdf_korder(F,n,k,x)-0.5;
    %calculating the actual median for the k order stat
    guess=mean(F);
    %mean of distribution F is the initial guess
    med=fzero(func,guess);
    %fzero starts at the initial guess and converges to the actual root of 
    %the function f(x)=0
end


%% Functions for Question L)

function sims=simulate(nsims,F,n)
    sims=random(F,[nsims,n]);
end

function bestk=kbest(F,nsims,n)
% kbest gets an approx k that gives the highest payoff for a certain number 
% of simulations
    set_values=zeros(1, n); %creating a vector of 0s
    simulations=simulate(nsims,F,n);
    for k = 1:n
        th=mediian(F, n, k).*ones(length(mediian(F, n, k)), n);
        th(end) = 0;
        [~,i_star] = chooseBox(th(k), simulations);
        set_values(k) = mean(i_star);
    end
    %for k from 1 to n simulating the median function defined in a J and
    %then applying the chooseBox function defined in C and getting its mean
    %over the number of simulations

    [~, bestk] = max(set_values);
end
    
