function [M] = HuInvariantMoments(A)
%% function [M] = HUInvariantMoments(A)
%
% This function Calculates the Seven Invariant Moments for the image A
% The output of this function is a Vector M called the Feature vector
% The vector M is a column vector containing the moments M1,M2,...,M7
%
% developed by Prof. Rogério Caldas Pinto @ IST

[m,n]=size(A);
moo=sum(sum(A));

m1o=0;
mo1=0;
for x=0:m-1
    for y=0:n-1
        m1o=m1o+(x)*A(x+1,y+1);
        mo1=mo1+(y)*A(x+1,y+1);
    end
end

n20=cent_moment(2,0,A,moo,mo1,m1o);
n02=cent_moment(0,2,A,moo,mo1,m1o);
n11=cent_moment(1,1,A,moo,mo1,m1o);
n30=cent_moment(3,0,A,moo,mo1,m1o);
n12=cent_moment(1,2,A,moo,mo1,m1o);
n21=cent_moment(2,1,A,moo,mo1,m1o);
n03=cent_moment(0,3,A,moo,mo1,m1o);

% First Moment
M1=n20+n02;
% Second Moment
M2=(n20-n02)^2+4*n11^2;

% Third Moment
M3=(n30-3*n12)^2+(3*n21-n03)^2;

% Fourth Moment
M4=(n30+n12)^2+(n21+n03)^2;

% Fifth Moment
M5=(n30-3*n21)*(n30+n12)*[(n30+n12)^2-3*(n21+n03)^2]+(3*n21-n03)*(n21+n03)*[3*(n30+n12)^2-(n21+n03)^2];

% Sixth Moment
M6=(n20-n02)*[(n30+n12)^2-(n21+n03)^2]+4*n11*(n30+n12)*(n21+n03);

% Seventh Moment
M7=(3*n21-n03)*(n30+n12)*[(n30+n12)^2-3*(n21+n03)^2]-(n30+3*n12)*(n21+n03)*[3*(n30+n12)^2-(n21+n03)^2];


% The vector M is a column vector containing M1,M2,....M7
M=[M1    M2     M3    M4     M5    M6    M7];

function n_pq=cent_moment(p,q,A,moo,mo1,m1o)
[m n]=size(A);

xx=m1o/moo;
yy=mo1/moo;

mu_oo=moo;

mu_pq=0;
for ii=0:m-1
    x=ii-xx;
    for jj=0:n-1
        y=jj-yy;
        mu_pq=mu_pq+(x)^p*(y)^q*A(ii+1,jj+1);
    end
end

gamma = 0.5*(p+q)+1;
n_pq = mu_pq/moo^(gamma);




