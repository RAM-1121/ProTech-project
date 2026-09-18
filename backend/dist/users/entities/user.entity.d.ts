export declare enum UserRole {
    CUSTOMER = "customer",
    EXECUTIVE = "executive",
    ADMIN = "admin"
}
export declare class User {
    id: string;
    email: string;
    phone: string;
    savedAddresses: string[];
    passwordHash: string;
    role: UserRole;
    firstName: string;
    lastName: string;
    currentLocation: {
        type: 'Point';
        coordinates: [number, number];
    };
    createdAt: Date;
    updatedAt: Date;
}
