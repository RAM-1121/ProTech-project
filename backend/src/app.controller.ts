import { Controller, Get, Post, Body, UnauthorizedException } from '@nestjs/common';
import { AppService } from './app.service';
import { UsersService } from './users/users.service';

@Controller()
export class AppController {
  constructor(
    private readonly appService: AppService,
    private readonly usersService: UsersService,
  ) {}

  @Get()
  getHello(): string {
    return this.appService.getHello();
  }

  @Post('login')
  async login(@Body('mobile') mobile: string, @Body('employeeId') employeeId: string, @Body('role') role: string) {
    if (role === 'admin') {
      const masterAdmins = ['7731836976'];
      const assistantAdmins = ['9908090202', '6303798398'];
      
      if (masterAdmins.includes(mobile)) {
        return { token: 'mock-jwt-token-master-admin', user: { mobile, role: 'master_admin' } };
      } else if (assistantAdmins.includes(mobile)) {
        return { token: 'mock-jwt-token-assistant-admin', user: { mobile, role: 'assistant_admin' } };
      } else {
        return { token: 'mock-jwt-token-master-admin', user: { mobile, role: 'master_admin' } };
      }
    }

    if (role === 'executive') {
      if (!employeeId || employeeId.trim() === '') {
        throw new UnauthorizedException('Invalid Employee ID');
      }

      // Check the database for the executive
      const employee = await this.usersService.findByEmployeeId(employeeId.trim());
      if (!employee) {
        throw new UnauthorizedException('Employee ID not found. Please register first.');
      }

      return {
        token: `mock-jwt-token-executive-${employee.employeeId}`,
        user: { employeeId: employee.employeeId, name: employee.firstName, role },
      };
    }

    // Allow other roles to log in normally for now
    return {
      token: 'mock-jwt-token',
      user: { mobile, role },
    };
  }
}
