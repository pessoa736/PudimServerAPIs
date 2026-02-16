-- Ensure local repository modules are preferred during tests
package.path = "./PudimServer/?.lua;./PudimServer/?/init.lua;" .. package.path
