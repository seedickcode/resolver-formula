#####################################
##### Salt Formula For Resolver #####
#####################################

{% if salt['pillar.get']('resolver:use_resolvconf', True) %}
  {% set is_resolvconf_enabled = grains['os_family'] in ('Debian') and 
        (salt['pkg.latest_version']('resolvconf') or 
         salt['pkg.latest_version']('resolvconf')) %}
{% else %}
  {% set is_resolvconf_enabled = False %}
{% endif %}

resolvconf-manage:
  {% if is_resolvconf_enabled %}
  pkg.installed:
  {% else %}
  pkg.purged:
  {% endif %}
    - name: resolvconf
    - require_in:
      - file: resolv-file

# Resolver Configuration
resolv-file:
  file.managed:
    {% if is_resolvconf_enabled %}
    - name: /etc/resolvconf/resolv.conf.d/base
    {% else %}
    - name: /etc/resolv.conf
    {% endif %}
    - user: root
    - group: root
    - mode: '0644'
    - source: salt://resolver/files/resolv.conf
    - template: jinja
    - defaults:
        nameservers: {{ salt['pillar.get']('resolver:nameservers', ['8.8.8.8','8.8.4.4']) }}
        searchpaths: {{ salt['pillar.get']('resolver:searchpaths', [salt['grains.get']('domain'),]) }}
        options: {{ salt['pillar.get']('resolver:options', []) }}
        domain: {{ salt['pillar.get']('resolver:domain') }}

{% if is_resolvconf_enabled %}
resolv-update:
  cmd.run:
    - name: resolvconf -u
    - onchanges:
      - file: resolv-file
{% endif %}
