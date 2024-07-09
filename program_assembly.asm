start:
    lw s0, 0x00000008   	# s0 -> starting address of an array
    lw s1, 0x00000004   	# s1 -> array size
    addi s2, zero, 0    	# s2 -> loop counter

#-------------------------MAIN LOOP-------------------------------------------

loop:
    beq s2, s1, loop 	# Terminate the loop
    lw a0, 0x0(s0)      	# a0 -> current array element
    jal primeCheck
    sw a0, 0x0(s0)      	# Store the return value
    addi s0, s0, 0x4    	# Move to the next element
    addi s2, s2, 1
    beq zero, zero, loop

#-------------------------PRIME CHECKING SUBROUTINE---------------------------

primeCheck:
    addi t0, zero, 2    	# t0 -> prime number candidate (initially, equals to 2)
    blt a0, t0, notPrime	# If input is less than 2, it is not a prime
primeLoop:
    beq a0, t0, prime       	# If the number equals the current prime candidate, it is a prime
    rem t1, a0, t0          	# t1 -> remainder of input division by the prime candidate
    beq t1, zero, notPrime     	# If remainder is 0, the number is not prime
    addi t0, t0, 1          	# Increment the prime candidate
    beq zero, zero, primeLoop

prime:
    addi a0, zero, 1    	# Set a0 to 1
    jalr zero, ra, 0    	# Return

notPrime:
    addi a0, zero, 0    	# Set a0 to 0
    jalr zero, ra, 0    	# Return

loopEnd:
