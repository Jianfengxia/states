openjdk_jdk:
  pkg:
    - purged
    - name: openjdk-7-jdk

{#- this pkg need to be removed, or openjdk_jre_headless cannot be removed #}
openjdk_jre:
  pkg:
    - purged
    - name: openjdk-7-jre
