Authorization
=============

This document provides information about the authorization process in the application. It outlines the necessary steps and considerations for implementing authorization effectively.

.. spec:: A requirement related to Authorization
   :id: S_AUTHN_001
   :links: R_AUTH_001

   The app requires authorization after successful authentication.
   See :need:`R_AUTH_001`.

   .. list-table:: Authorization Levels
      :header-rows: 1
      :widths: 20 30 50

      * - Level
        - Access Type
        - Description
      * - Admin
        - Full Access
        - Complete system administration privileges
      * - User
        - Limited Access
        - Standard user operations and data access
      * - Guest
        - Read Only
        - View-only access to public resources

Also allows for free-text need references, see :need:`R_AUTH_001`.
