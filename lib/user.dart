class User {
    static int userId = 0;
    static String userAuthToken = "";
    static String userEmail = "";

    static void clearUser(){
        userId = 0;
        userAuthToken = "";
        userEmail = "";
    }
}