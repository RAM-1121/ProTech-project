import { Controller, Get, Post, Body, Patch, Param, Delete, BadRequestException, UnauthorizedException, Headers } from '@nestjs/common';
import { UsersService } from './users.service';

@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  private extractEmployeeId(authHeader: string): string {
    if (!authHeader || !authHeader.startsWith('Bearer mock-jwt-token-executive-')) {
      throw new UnauthorizedException('Invalid executive token');
    }
    return authHeader.replace('Bearer mock-jwt-token-executive-', '');
  }

  @Get('executive/wallet')
  getWallet(@Headers('authorization') auth: string) {
    const employeeId = this.extractEmployeeId(auth);
    return this.usersService.getWalletDetails(employeeId);
  }

  @Post('executive/wallet/redeem')
  redeemPoints(@Headers('authorization') auth: string, @Body('amount') amount: number) {
    const employeeId = this.extractEmployeeId(auth);
    return this.usersService.redeemPoints(employeeId, amount);
  }

  @Get('executives')
  findAllExecutives() {
    return this.usersService.findAllExecutives();
  }

  @Get('executives/profile/:employeeId')
  async getExecutiveProfile(@Param('employeeId') employeeId: string) {
    const user = await this.usersService.findByEmployeeId(employeeId);
    if (!user) {
      throw new BadRequestException('Executive not found');
    }
    return user;
  }

  @Post('executives')
  async createExecutive(@Headers('authorization') auth: string, @Body() createExecutiveDto: any) {
    if (auth === 'Bearer mock-jwt-token-assistant-admin') {
      throw new UnauthorizedException('Assistant Admins are not allowed to create employees.');
    }
    if (!createExecutiveDto.employeeId) {
      throw new BadRequestException('Employee ID is required');
    }
    const existing = await this.usersService.findByEmployeeId(createExecutiveDto.employeeId);
    if (existing) {
      throw new BadRequestException('Employee ID already exists');
    }
    return this.usersService.createExecutive(createExecutiveDto);
  }

  @Patch('executives/:id')
  updateExecutive(@Param('id') id: string, @Body() updateExecutiveDto: any) {
    return this.usersService.updateExecutive(id, updateExecutiveDto);
  }

  @Delete('executives/:id')
  removeExecutive(@Headers('authorization') auth: string, @Param('id') id: string) {
    if (auth === 'Bearer mock-jwt-token-assistant-admin') {
      throw new UnauthorizedException('Assistant Admins are not allowed to delete employees.');
    }
    return this.usersService.removeExecutive(id);
  }
}
