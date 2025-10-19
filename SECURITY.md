# Security Policy

## 🔐 Reporting Security Issues

If you discover a security vulnerability, please email the project maintainers directly. Do not open a public issue.

## 🛡️ Security Best Practices

### API Keys and Credentials

This project uses Firebase for backend services. **Never commit sensitive credentials to version control.**

#### Protected Files (in .gitignore)
- `.env` - Environment variables
- `lib/firebase_options.dart` - Flutter Firebase configuration
- `web/firebase-config.js` - Web Firebase configuration

#### Template Files (safe to commit)
- `.env.example` - Environment variable template
- `lib/firebase_options.dart.example` - Flutter config template
- `web/firebase-config.js.example` - Web config template

### If You Accidentally Committed Credentials

1. **Immediately rotate/regenerate all exposed credentials:**
   - Firebase: Go to Project Settings → Service Accounts → Generate new private key
   - Update Firebase Security Rules to restrict access

2. **Remove credentials from Git history:**
   ```bash
   # Use git-filter-repo (recommended) or BFG Repo-Cleaner
   git filter-repo --invert-paths --path lib/firebase_options.dart
   git filter-repo --invert-paths --path web/index.html
   ```

3. **Force push to remote:**
   ```bash
   git push origin --force --all
   ```

4. **Update all team members** to re-clone the repository

### Firebase Security Rules

Always restrict write access to authorized users only:

**Storage Rules:**
```
allow write: if request.auth != null && 
  (request.auth.uid == 'AUTHORIZED_UID_1' || 
   request.auth.uid == 'AUTHORIZED_UID_2');
```

**Database Rules:**
```json
".write": "auth != null && (auth.uid === 'AUTHORIZED_UID_1' || auth.uid === 'AUTHORIZED_UID_2')"
```

## 🔍 Security Checklist

- [ ] Never commit `.env` files
- [ ] Never commit `firebase_options.dart` with real credentials
- [ ] Never commit `firebase-config.js` with real credentials
- [ ] Always use `.example` template files in the repository
- [ ] Restrict Firebase rules to authorized users only
- [ ] Regularly rotate API keys and credentials
- [ ] Use HTTPS for all production deployments
- [ ] Enable Firebase App Check for production
- [ ] Review Firebase Security Rules regularly

## 📚 Additional Resources

- [Firebase Security Rules Documentation](https://firebase.google.com/docs/rules)
- [Firebase Authentication Best Practices](https://firebase.google.com/docs/auth/admin/manage-sessions)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
