# Production
ALLOWED_HOSTS = [
    '{{cops_terralego_hostname}}',
    {% for url in cops_terralego_alternate_hostname %}
    '{{url}}',
    {% endfor %}
]
CORS_ORIGIN_WHITELIST = (
    '{{cops_terralego_hostname}}',
)

# ADMINS = ()
MEDIA_ACCEL_REDIRECT=False

{% if cops_terralego_devmode %}
CORS_ORIGIN_ALLOW_ALL=True
DEBUG=True
{% endif %}
# This need to be changed in production
SECRET_KEY="{{ cops_terralego_secret_key }}"
DJANGO__DEFAULT_FROM_EMAIL='{{ cops_terralego_default_from_email }}'
# EMAIL_HOST = '{{ cops_terralego_email_server }}'
# EMAIL_HOST_USER = '{{ cops_terralego_email_host_user }}'
# EMAIL_HOST_PASSWORD = '{{ cops_terralego_email_host_password }}'
# EMAIL_PORT = '{{ cops_terralego_email_host_port }}'
USE_TLS = {{ cops_terralego_email_use_tls }}
EMAIL_BACKEND='django.core.mail.backends.smtp.EmailBackend'
EMAIL_HOST='mailcatcher'
DJANGO__EMAIL_PORT=25

#SERVER_EMAIL = '{{ cops_terralego_server_email }}'
